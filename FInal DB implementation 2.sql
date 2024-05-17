USE Project_Team_3;

-- USERS

CREATE TABLE Users (
    User_id INT IDENTITY(1,1) PRIMARY KEY,
    FName VARCHAR(50) NOT NULL,
    LName VARCHAR(50) NOT NULL,
    Email_id VARCHAR(255) NOT NULL UNIQUE,
    Password VARCHAR(255) NOT NULL
);


--Creating function to check valid email
CREATE FUNCTION IsValidEmail (@Email VARCHAR(255))
RETURNS BIT
AS
BEGIN
    DECLARE @IsValid BIT = 0;

    IF CHARINDEX('@', @Email) > 0
        SET @IsValid = 1;

    RETURN @IsValid;
END;

--adding the constraint to the table
ALTER TABLE Users
ADD CONSTRAINT CHK_ValidEmailDomain CHECK (dbo.IsValidEmail(Email_id) = 1);


-- Creating Subscription Type Table
CREATE TABLE SubscriptionType (
    Subscription_type_id INT IDENTITY(1,1) PRIMARY KEY,
    SubscriptionName VARCHAR(50) NOT NULL,
    Duration_days INT NOT NULL, -- Renamed for clarity
    SubscriptionAmount DECIMAL(10, 2) NOT NULL -- Allowing for cents in the amount
);


-- Creating Subscription Table
CREATE TABLE Subscription (
    Subscription_id INT IDENTITY(101,1) PRIMARY KEY,
    Subscription_type_id INT NOT NULL,
    User_id INT NOT NULL,
    Transaction_id INT NOT NULL,
    StartDate DATE DEFAULT GETDATE(), -- Set StartDate to today's date by default
    EndDate DATE, -- Calculate EndDate based on Duration_days
    Status TINYINT NOT NULL, -- Changed to TINYINT for status
    FOREIGN KEY (Subscription_type_id) REFERENCES SubscriptionType(Subscription_type_id),
    FOREIGN KEY (User_id) REFERENCES Users(User_id),
    FOREIGN KEY (Transaction_id) REFERENCES TransactionTable(Transaction_id)
);
--Adding contraint to the subscription table
ALTER TABLE Subscription
ADD CONSTRAINT CHK_EndDate CHECK (EndDate >= StartDate);

--Creating a trigger to update the Startdate
CREATE TRIGGER UpdateSubscriptionStartDate
ON TransactionTable
AFTER INSERT, UPDATE
AS
BEGIN
    IF (SELECT Status FROM inserted) = 1
    BEGIN
        UPDATE Subscription
        SET StartDate = (SELECT [Date] FROM inserted)
        WHERE Subscription_id = (SELECT Subscription_id FROM inserted)
            AND Status = 1;
    END
END;


--Creating a trigger to update the enddate on insertion
CREATE TRIGGER UpdateEndDate
ON Subscription
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE s
    SET EndDate = DATEADD(DAY, st.Duration_days, s.StartDate)
    FROM Subscription s
    JOIN SubscriptionType st ON s.Subscription_type_id = st.Subscription_type_id
    WHERE s.Subscription_id IN (SELECT Subscription_id FROM inserted)
END;

-- Creating Transaction Table
CREATE TABLE TransactionTable (
    Transaction_id INT IDENTITY(1011,1) PRIMARY KEY,
    User_id INT NOT NULL,
    Subscription_id INT NOT NULL,
    Payment_method VARCHAR(50) NOT NULL,
    Status TINYINT NOT NULL, -- Changed to TINYINT for status
    Date DATE NOT NULL,
    FOREIGN KEY (User_id) REFERENCES Users(User_id) -- Assuming there is a Users table with User_id as PK
    
);
---------------------------------------------------------------------------------------------------------------

--Creating function to calculate age
CREATE FUNCTION dbo.CalculateAge(@BirthDate DATE)
RETURNS INT
AS
BEGIN
    DECLARE @Age INT;

    -- Calculate age using DATEDIFF function
    SET @Age = DATEDIFF(YEAR, @BirthDate, GETDATE());

    -- Adjust age if the birthday hasn't occurred this year yet
    IF (MONTH(@BirthDate) > MONTH(GETDATE())) OR
       (MONTH(@BirthDate) = MONTH(GETDATE()) AND DAY(@BirthDate) > DAY(GETDATE()))
    BEGIN
        SET @Age = @Age - 1; -- Subtract 1 year if birthday hasn't occurred yet
    END

    RETURN @Age;
END;


--Creating function to calculate BMI
Create FUNCTION calculate_bmi(
    @WeightKg DECIMAL(5, 2),
    @HeightM DECIMAL(5, 2)
)
RETURNS DECIMAL(5, 2)
AS
BEGIN
    DECLARE @BMI DECIMAL(5, 2);

    -- Check if height is not zero to avoid division by zero
    IF @HeightM <> 0
    BEGIN
        SET @BMI = @WeightKg / POWER(@HeightM, 2);
    END
    ELSE
    BEGIN
        SET @BMI = NULL; -- Handle division by zero or NULL height
    END

    RETURN @BMI;
END;


-- Creating Nutritional Profile Table
CREATE TABLE NutritionalProfile (
    Nutrition_id INT IDENTITY(201,1) PRIMARY KEY,
    User_id INT UNIQUE NOT NULL,
    Gender VARCHAR(20) NOT NULL,
    BirthDate DATE NOT NULL,
    Age as dbo.CalculateAge(BirthDate),
    Height DECIMAL(5, 2) NOT NULL,
    Weight DECIMAL(5, 2) NOT NULL,
    BMI as dbo.calculate_bmi(weight,height) ,
    FOREIGN KEY (User_id) REFERENCES Users(User_id)
);


-- Creating Goal Type Table
CREATE TABLE GoalType (
    Goal_type_id INT IDENTITY(111,1) PRIMARY KEY,
    GoalType VARCHAR(50) NOT NULL -- Increased length for goal type names
);

-- Creating Goal Table
CREATE TABLE Goal (
    Goal_id INT IDENTITY(123,1) PRIMARY KEY,
    User_id INT NOT NULL,
    Goal_type_id INT NOT NULL,
    Target_date DATE NOT NULL,
    UNIQUE(User_id, Goal_type_id),
    FOREIGN KEY (User_id) REFERENCES Users(User_id),
    FOREIGN KEY (Goal_type_id) REFERENCES GoalType(Goal_type_id)
);


--------------------------------------------------------------------------------------


-- Creating Activity Log Table
CREATE TABLE ActivityLog (
    Activity_log_id INT IDENTITY(1,1) PRIMARY KEY,
    User_id INT NOT NULL,
    ActivityDescription VARCHAR(500) NOT NULL,
    Duration TIME NOT NULL,
    CaloriesBurned DECIMAL(6, 2) NOT NULL, -- Changed to DECIMAL for potential precision
    Date DATE NOT NULL,
    FOREIGN KEY (User_id) REFERENCES Users(User_id)
);

-- Creating Water Log Table
CREATE TABLE WaterLog (
    Water_log_id INT IDENTITY(1,1) PRIMARY KEY,
    User_id INT NOT NULL,
    Date DATE NOT NULL,
    AmountOfWater DECIMAL(5, 2) NOT NULL, -- Changed to DECIMAL for potential precision
    FOREIGN KEY (User_id) REFERENCES Users(User_id)
);

-- Create the function
CREATE FUNCTION CheckWaterAmount (@AmountOfWater DECIMAL(5, 2))
RETURNS BIT
AS
BEGIN
    DECLARE @IsValid BIT = 0;

    -- Check if the amount of water is between 0 and 5000 (adjust as needed)
    IF @AmountOfWater >= 0 AND @AmountOfWater <= 5000
        SET @IsValid = 1;

    RETURN @IsValid;
END;

-- Alter the WaterLog table to add the constraint
ALTER TABLE WaterLog
ADD CONSTRAINT CHK_ValidWaterAmount CHECK (dbo.CheckWaterAmount(AmountOfWater) = 1);


-- Creating Sleep Log Table
CREATE TABLE SleepLog (
    Sleep_log_id INT IDENTITY(1,1) PRIMARY KEY,
    User_id INT NOT NULL,
    Date DATE NOT NULL,
    DurationOfSleep TIME NOT NULL, -- Assuming duration will not exceed 24 hours
    FOREIGN KEY (User_id) REFERENCES Users(User_id)
);

---------------------------------------------------------------------------------------------------

-- Creating Nutritional Log Table
CREATE TABLE NutritionalLog (
    Nutri_log_id INT IDENTITY(301,1)PRIMARY KEY,
    User_id INT NOT NULL,
    Meal_id INT NOT NULL,
    Date DATE NOT NULL,
    FOREIGN KEY (User_id) REFERENCES Users(User_id),
    FOREIGN KEY (Meal_id) REFERENCES Meal(Meal_id)
);

-- Creating Meal Table
CREATE TABLE Meal (
    Meal_id  INT IDENTITY(1,1) PRIMARY KEY,
    Meal_type VARCHAR(20) NOT NULL -- Increased length for descriptive meal types
);

-- Creating Food Item Table
CREATE TABLE FoodItem (
    Food_item_id  INT IDENTITY(901,1) PRIMARY KEY,
    Nutri_log_id INT NOT NULL,
    Food_id INT NOT NULL,
    Serving_size DECIMAL(5, 2) NOT NULL, -- Changed to DECIMAL for potential precision
    FOREIGN KEY (Nutri_log_id) REFERENCES NutritionalLog(Nutri_log_id),
    FOREIGN KEY (Food_id) REFERENCES Food(Food_id)
);

-- Creating Food Table
CREATE TABLE Food (
    Food_id  INT IDENTITY(41,1) PRIMARY KEY,
    Food_name VARCHAR(50) NOT NULL,
    Calories DECIMAL(6, 2) NOT NULL, -- Changed to DECIMAL for potential precision
    Nutrients VARCHAR(255) NOT NULL, -- Increased length for multiple nutrients
    Instructions VARCHAR(5000),
    MeasurementStandard VARCHAR(20) -- Increased length if needed for complex standards
);




ALTER TABLE [Users]
DROP COLUMN Password;

ALTER TABLE [Users]
ADD HashedPassword VARCHAR(64);


---Adding users data in users table

INSERT INTO Project_Team_3.dbo.Users (FName, LName, Email_id, HashedPassword)
VALUES ('John', 'Doe', 'john.doe@example.com', CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'Boston@123'), 2));

INSERT INTO Project_Team_3.dbo.Users (FName, LName, Email_id, HashedPassword)
VALUES ('Ash', 'Pura', 'ash.pura@example.com', CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'xfinity@2022'), 2));

INSERT INTO Project_Team_3.dbo.Users (FName, LName, Email_id, HashedPassword)
VALUES ('harry', 'Puttar', 'harry.puttar@example.com', CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'puttar@2033'), 2));

INSERT INTO Project_Team_3.dbo.Users (FName, LName, Email_id, HashedPassword)
VALUES ('angilina', 'marry', 'angi.marry@example.com', CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'angimarry@3071'), 2));


INSERT INTO Project_Team_3.dbo.Users (FName, LName, Email_id, HashedPassword)
VALUES ('yash', 'gupta', 'yashgupta@example.com', CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'firangi@1996'), 2));



INSERT INTO Project_Team_3.dbo.Users (FName, LName, Email_id, HashedPassword)
VALUES ('jagga', 'daku', 'jagga.daku@example.com', CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'dakujagga116'), 2));


INSERT INTO Project_Team_3.dbo.Users (FName, LName, Email_id, HashedPassword)
VALUES ('manu', 'pund', 'manupund@example.com', CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'miss_pund@11'), 2));


INSERT INTO Project_Team_3.dbo.Users (FName, LName, Email_id, HashedPassword)
VALUES ('sarika', 'hegde', 'sarikah@example.com', CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'hegde@3987'), 2));



INSERT INTO Project_Team_3.dbo.Users (FName, LName, Email_id, HashedPassword)
VALUES ('neha', 'patil', 'nehapatil@example.com', CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'nehaP@888'), 2));


INSERT INTO Project_Team_3.dbo.Users (FName, LName, Email_id, HashedPassword)
VALUES ('prady', 'sharma', 'prady.sharma@example.com', CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'Weekend@today'), 2));


select * FROM Project_Team_3.dbo.Users;

--insert data into subscription Type table 

INSERT INTO Project_Team_3.dbo.SubscriptionType (SubscriptionName, Duration_days, SubscriptionAmount) 
VALUES 
    ('Basic', 30, 10.00),
    ('Standard', 90, 25.00),
    ('Premium', 180, 50.00),
    ('Enterprise', 365, 100.00);
   
select * FROM Project_Team_3.dbo.SubscriptionType; 


--Insert data into Food table

INSERT INTO Project_Team_3.dbo.Food (Food_name, Calories, Nutrients, Instructions, MeasurementStandard)
VALUES
('Apple', 95, 'Fiber: 4g, Vitamin C: 14%', 'Eat raw or cook as desired.', 'Unit'),
('Banana', 105, 'Fiber: 3g, Vitamin B6: 25%', 'Peel and eat raw.', 'Unit'),
('Orange', 62, 'Fiber: 3g, Vitamin C: 93%', 'Peel and eat raw or juice.', 'Unit'),
('Blueberries', 84, 'Fiber: 3.6g, Vitamin C: 24%', 'Eat raw or use in recipes.', 'Cup'),
('Strawberries', 53, 'Fiber: 2g, Vitamin C: 159%', 'Eat raw or add to dishes.', 'Cup'),
('Grapes', 104, 'Carbs: 27g, Vitamin C: 27%', 'Eat raw or freeze for a snack.', 'Cup'),
('Kiwi', 42, 'Vitamin C: 71%, Vitamin K: 31%', 'Peel and eat raw or add to salads.', 'Unit'),
('Peach', 59, 'Vitamin C: 17%, Fiber: 2g', 'Eat raw or bake in desserts.', 'Unit'),
('Pineapple', 82, 'Vitamin C: 131%, Manganese: 76%', 'Cut and eat raw or grill.', 'Cup'),
('Watermelon', 30, 'Vitamin C: 25%, Hydration: 92% water', 'Cut and eat raw.', 'Cup'),
('Oatmeal', 158, 'Fiber: 4g, Protein: 6g', 'Boil in water or milk until creamy.', 'Cup'),
('Scrambled Eggs', 143, 'Protein: 13g, Fat: 10g', 'Beat eggs, cook in skillet until set.', 'Servings'),
('Pancakes', 89, 'Carbs: 12g, Protein: 2.5g', 'Mix batter, pour on griddle, cook until bubbly.', 'Unit'),
('Avocado Toast', 240, 'Fiber: 7g, Fat: 15g', 'Mash avocado on toast, season to taste.', 'Unit'),
('Granola with Yogurt', 200, 'Protein: 8g, Fiber: 2g', 'Layer yogurt with granola and fruit.', 'Bowl'),
('Smoothie Bowl', 250, 'Fiber: 5g, Protein: 6g', 'Blend fruits with yogurt, top with seeds.', 'Bowl'),
('French Toast', 160, 'Carbs: 30g, Protein: 8g', 'Soak bread in egg mix, pan-fry until golden.', 'Slice'),
('Bagel with Cream Cheese', 290, 'Carbs: 56g, Protein: 11g', 'Toast bagel, spread with cream cheese.', 'Unit'),
('Quinoa Salad', 222, 'Protein: 8g, Fiber: 5g', 'Mix cooked quinoa with vegetables and dressing.', 'Cup'),
('Vegetable Soup', 158, 'Fiber: 4g, Protein: 5g', 'Simmer vegetables in stock until tender.', 'Bowl'),
('Chicken Caesar Salad', 470, 'Protein: 40g, Fat: 26g', 'Toss lettuce with dressing, chicken, croutons.', 'Bowl'),
('Spaghetti Carbonara', 670, 'Protein: 20g, Fat: 30g', 'Cook pasta, mix with egg, cheese, bacon.', 'Plate'),
('Grilled Salmon', 280, 'Protein: 23g, Fat: 13g', 'Grill salmon, season as desired.', 'Unit'),
('Beef Stir Fry', 320, 'Protein: 25g, Carbs: 20g', 'Stir-fry beef and vegetables, serve with rice.', 'Cup'),
('Chicken Tacos', 200, 'Protein: 20g, Carbs: 22g', 'Cook chicken, serve in tortillas with toppings.', 'Unit'),
('Vegetarian Pizza', 280, 'Carbs: 40g, Fat: 10g', 'Top dough with sauce, cheese, veggies; bake.', 'Slice'),
('Turkey Sandwich', 330, 'Protein: 25g, Carbs: 45g', 'Layer turkey, cheese, veggies on bread.', 'Unit'),
('Ratatouille', 110, 'Fiber: 4g, Vitamin C: 30%', 'Simmer chopped vegetables in tomato sauce.', 'Cup'),
('Lentil Soup', 230, 'Protein: 18g, Fiber: 15g', 'Cook lentils with vegetables and spices.', 'Bowl'),
('Falafel Wrap', 550, 'Protein: 15g, Fiber: 9g', 'Wrap falafel, vegetables, sauce in flatbread.', 'Unit');



select * From Project_Team_3.dbo.Food;


--Insert data into Meal table 
INSERT INTO Project_Team_3.dbo.Meal (Meal_type)
VALUES('Dinner'),('Lunch'),('Breakfast'),('Snack');

select * From Project_Team_3.dbo.Meal;


--Insert data into NutritionalLog table

INSERT INTO Project_Team_3.dbo.NutritionalLog (User_id, Meal_id, [Date])
VALUES
-- User 1: John Doe
(1, 1, '2023-04-01'), (1, 2, '2023-04-01'), (1, 3, '2023-04-01'), (1, 4, '2023-04-01'),
(1, 1, '2023-04-02'), (1, 2, '2023-04-02'), (1, 3, '2023-04-02'), (1, 4, '2023-04-02'),
 
-- User 3: Ash Pura
(3, 1, '2023-04-01'), (3, 2, '2023-04-01'), (3, 3, '2023-04-01'), (3, 4, '2023-04-01'),
(3, 1, '2023-04-02'), (3, 2, '2023-04-02'), (3, 3, '2023-04-02'), (3, 4, '2023-04-02'),
 
-- User 5: Harry Puttar
(5, 1, '2023-04-01'), (5, 2, '2023-04-01'), (5, 3, '2023-04-01'), (5, 4, '2023-04-01'),
(5, 1, '2023-04-02'), (5, 2, '2023-04-02'), (5, 3, '2023-04-02'), (5, 4, '2023-04-02'),
 
-- User 6: Angilina Marry
(6, 1, '2023-04-01'), (6, 2, '2023-04-01'), (6, 3, '2023-04-01'), (6, 4, '2023-04-01'),
(6, 1, '2023-04-02'), (6, 2, '2023-04-02'), (6, 3, '2023-04-02'), (6, 4, '2023-04-02'),
 
-- User 7: Yash Gupta
(7, 1, '2023-04-01'), (7, 2, '2023-04-01'), (7, 3, '2023-04-01'), (7, 4, '2023-04-01'),
(7, 1, '2023-04-02'), (7, 2, '2023-04-02'), (7, 3, '2023-04-02'), (7, 4, '2023-04-02'),
 
-- User 8: Jagga Daku
(8, 1, '2023-04-01'), (8, 2, '2023-04-01'), (8, 3, '2023-04-01'), (8, 4, '2023-04-01'),
(8, 1, '2023-04-02'), (8, 2, '2023-04-02'), (8, 3, '2023-04-02'), (8, 4, '2023-04-02'),
 
-- User 9: Manu Pund
(9, 1, '2023-04-01'), (9, 2, '2023-04-01'), (9, 3, '2023-04-01'), (9, 4, '2023-04-01'),
(9, 1, '2023-04-02'), (9, 2, '2023-04-02'), (9, 3, '2023-04-02'), (9, 4, '2023-04-02'),
 
-- User 10: Sarika Hegde
(10, 1, '2023-04-01'), (10, 2, '2023-04-01'), (10, 3, '2023-04-01'), (10, 4, '2023-04-01'),
(10, 1, '2023-04-02'), (10, 2, '2023-04-02'), (10, 3, '2023-04-02'), (10, 4, '2023-04-02');


INSERT INTO Project_Team_3.dbo.NutritionalLog (User_id, Meal_id, [Date])
VALUES
(11, 1, '2023-04-01'), (11, 2, '2023-04-01'), (11, 3, '2023-04-01'), (11, 4, '2023-04-01'),
(11, 1, '2023-04-02'), (11, 2, '2023-04-02'), (11, 3, '2023-04-02'), (11, 4, '2023-04-02'),

(12, 1, '2023-04-01'), (12, 2, '2023-04-01'), (12, 3, '2023-04-01'), (12, 4, '2023-04-01'),
(12, 1, '2023-04-02'), (12, 2, '2023-04-02'), (12, 3, '2023-04-02'), (12, 4, '2023-04-02');


SELECT * from Project_Team_3.dbo.NutritionalLog;


--Insert data into FoodItem table


INSERT INTO Project_Team_3.dbo.FoodItem (Nutri_log_id, Food_id, Serving_size)
VALUES (301, 41, 1);

INSERT INTO Project_Team_3.dbo.FoodItem (Nutri_log_id, Food_id, Serving_size)
VALUES (302, 42, 2);

INSERT INTO Project_Team_3.dbo.FoodItem (Nutri_log_id, Food_id, Serving_size)
VALUES
(303, 43, 1),   -- Orange
(304, 44, 2),   -- Blueberries
(305, 45, 1),   -- Strawberries
(306, 46, 2),   -- Grapes
(307, 47, 1),   -- Kiwi
(308, 48, 1),   -- Peach
(309, 49, 2),   -- Pineapple
(310, 50, 1),   -- Watermelon
(311, 51, 1),   -- Oatmeal
(312, 52, 1),   -- Scrambled Eggs
(313, 53, 1),   -- Pancakes
(314, 54, 1),   -- Avocado Toast
(315, 55, 1),   -- Granola with Yogurt
(316, 56, 1),   -- Smoothie Bowl
(317, 57, 1),   -- French Toast
(318, 58, 1),   -- Bagel with Cream Cheese
(319, 59, 1),   -- Quinoa Salad
(320, 60, 1),   -- Vegetable Soup
(321, 61, 1),   -- Chicken Caesar Salad
(322, 62, 1),   -- Spaghetti Carbonara
(323, 63, 1),   -- Grilled Salmon
(324, 64, 1),   -- Beef Stir Fry
(325, 65, 1),   -- Chicken Tacos
(326, 66, 1),   -- Vegetarian Pizza
(327, 67, 1),   -- Turkey Sandwich
(328, 68, 1),   -- Ratatouille
(329, 69, 1),   -- Lentil Soup
(330, 70, 1);   -- Falafel Wrap


INSERT INTO Project_Team_3.dbo.FoodItem (Nutri_log_id, Food_id, Serving_size)
VALUES
(331, 69, 1),    -- Lentil Soup
(332, 70, 1),    -- Falafel Wrap
(333, 41, 1.5),  -- Apple
(334, 42, 1),    -- Banana
(335, 43, 1),    -- Orange
(336, 44, 2),    -- Blueberries
(337, 45, 1),    -- Strawberries
(338, 46, 2),    -- Grapes
(339, 47, 1),    -- Kiwi
(340, 48, 1),    -- Peach
(341, 49, 2),    -- Pineapple
(342, 50, 1),    -- Watermelon
(343, 51, 1),    -- Oatmeal
(344, 52, 1),    -- Scrambled Eggs
(345, 53, 1),    -- Pancakes
(346, 54, 1),    -- Avocado Toast
(347, 55, 1),    -- Granola with Yogurt
(348, 56, 1),    -- Smoothie Bowl
(349, 57, 1),    -- French Toast
(350, 58, 1),    -- Bagel with Cream Cheese
(351, 59, 1),    -- Quinoa Salad
(352, 60, 1),    -- Vegetable Soup
(353, 61, 1),    -- Chicken Caesar Salad
(354, 62, 1),    -- Spaghetti Carbonara
(355, 63, 1),    -- Grilled Salmon
(356, 64, 1),    -- Beef Stir Fry
(357, 65, 1),    -- Chicken Tacos
(358, 66, 1),    -- Vegetarian Pizza
(359, 67, 1),    -- Turkey Sandwich
(360, 68, 1),    -- Ratatouille
(361, 69, 1),    -- Lentil Soup
(362, 70, 1);    -- Falafel Wrap

INSERT INTO Project_Team_3.dbo.FoodItem (Nutri_log_id, Food_id, Serving_size)
VALUES 
(363,41, 1),    -- Bagel with Cream Cheese
(364, 44, 1),    -- Quinoa Salad
(365, 45, 1),    -- Vegetable Soup
(366, 49, 1),    -- Chicken Caesar Salad
(367, 50, 1),    -- Spaghetti Carbonara
(368, 54, 1),    -- Grilled Salmon
(369, 64, 1),    -- Beef Stir Fry
(370, 65, 1),    -- Chicken Tacos
(371, 66, 1),    -- Vegetarian Pizza
(372, 67, 1),    -- Turkey Sandwich
(373, 68, 1),    -- Ratatouille
(374, 69, 1),    -- Lentil Soup
(375, 70, 1),
(376, 66, 1),    -- Vegetarian Pizza
(377, 67, 1),    -- Turkey Sandwich
(378, 68, 1),    -- Ratatouille
(379, 69, 1),    -- Lentil Soup
(380, 70, 1);




SELECT  * from Project_Team_3.dbo.FoodItem;


--Insert data into GoalType table

INSERT INTO Project_Team_3.dbo.GoalType (GoalType)
VALUES ('Weight Loss'), ('Muscle Gain'), ('Maintain Weight');


SELECT * FROM Project_Team_3.dbo.GoalType;



--Insert data into Goal Table

INSERT INTO Project_Team_3.dbo.Goal (User_id, Goal_type_id, Target_date)
VALUES (1, 111, '2024-05-01'), (3, 112, '2024-06-15'), (5, 113, '2024-07-30'),
       (6, 111, '2024-08-01'), (7, 112, '2024-09-15'), (8, 113, '2024-10-30'),
       (9, 111, '2024-11-01'), (10, 112, '2024-12-15');
      
SELECT * FROM Project_Team_3.dbo.Goal;






---Insert data into NutritionalProfile Table



INSERT INTO Project_Team_3.dbo.NutritionalProfile (User_id, Gender, BirthDate, Height, Weight)
VALUES 
(1, 'Male', '1990-01-15', 1.805, 75.3),
(3, 'Female', '1995-05-23', 1.652, 62.7),
(5, 'Male', '1978-11-10', 1.75, 80.0),
(6, 'Female', '1992-09-30', 1.60, 55.5),
(7, 'Male', '2000-03-05', 1.823, 85.6),
(8, 'Female', '1998-07-20', 1.707, 65.8),
(9, 'Male', '2002-12-28', 1.789, 78.2),
(10, 'Female', '1991-04-03', 1.634, 60.1),
(11, 'male', '1996-10-30', 1.634, 70.1),
(12, 'Female', '2000-05-23', 2.0, 80.1)
;



select * from Project_Team_3.dbo.NutritionalProfile;

--Insert data into SleepingLog

INSERT INTO Project_Team_3.dbo.SleepLog (User_id, [Date], DurationOfSleep)
VALUES 
(1, '2024-04-10', '07:30'),
(1, '2024-04-11', '08:00'),
(1, '2024-04-12', '07:45'),
(1, '2024-04-13', '08:15');

-- User 3 sleep logs
INSERT INTO Project_Team_3.dbo.SleepLog (User_id, [Date], DurationOfSleep)
VALUES 
(3, '2024-04-10', '08:15'),
(3, '2024-04-11', '08:30'),
(3, '2024-04-12', '07:45'),
(3, '2024-04-13', '08:00');

-- User 5 sleep logs
INSERT INTO Project_Team_3.dbo.SleepLog (User_id, [Date], DurationOfSleep)
VALUES 
(5, '2024-04-10', '07:45'),
(5, '2024-04-11', '08:30'),
(5, '2024-04-12', '08:00'),
(5, '2024-04-13', '08:15');

-- User 6 sleep logs
INSERT INTO Project_Team_3.dbo.SleepLog (User_id, [Date], DurationOfSleep)
VALUES 
(6, '2024-04-10', '08:00'),
(6, '2024-04-11', '08:15'),
(6, '2024-04-12', '08:30'),
(6, '2024-04-13', '07:45');

-- User 7 sleep logs
INSERT INTO Project_Team_3.dbo.SleepLog (User_id, [Date], DurationOfSleep)
VALUES 
(7, '2024-04-10', '07:30'),
(7, '2024-04-11', '08:00'),
(7, '2024-04-12', '08:15'),
(7, '2024-04-13', '08:30');

-- User 8 sleep logs
INSERT INTO Project_Team_3.dbo.SleepLog (User_id, [Date], DurationOfSleep)
VALUES 
(8, '2024-04-10', '08:15'),
(8, '2024-04-11', '08:30'),
(8, '2024-04-12', '07:45'),
(8, '2024-04-13', '08:00');

-- User 9 sleep logs
INSERT INTO Project_Team_3.dbo.SleepLog (User_id, [Date], DurationOfSleep)
VALUES 
(9, '2024-04-10', '05:30'),
(9, '2024-04-11', '04:45'),
(9, '2024-04-12', '06:00'),
(9, '2024-04-13', '03:15');

-- User 10 sleep logs
INSERT INTO Project_Team_3.dbo.SleepLog (User_id, [Date], DurationOfSleep)
VALUES 
(10, '2024-04-10', '05:00'),
(10, '2024-04-11', '08:15'),
(10, '2024-04-12', '04:30'),
(10, '2024-04-13', '07:45');

INSERT INTO Project_Team_3.dbo.SleepLog (User_id, [Date], DurationOfSleep)
VALUES 
(11, '2024-04-10', '06:00'),
(11, '2024-04-11', '07:15'),
(11, '2024-04-12', '06:30'),
(11, '2024-04-13', '07:45');

INSERT INTO Project_Team_3.dbo.SleepLog (User_id, [Date], DurationOfSleep)
VALUES 
(12, '2024-04-10', '07:00'),
(12, '2024-04-11', '07:15'),
(12, '2024-04-12', '07:30'),
(12, '2024-04-13', '07:45');


SELECT  * from Project_Team_3.dbo.SleepLog;


--Insert data into WaterLog Table 

INSERT INTO Project_Team_3.dbo.WaterLog (User_id, [Date], AmountOfWater)
VALUES 
(1, '2024-04-10', 2.5),
(1, '2024-04-11', 3.0),
(1, '2024-04-12', 2.7),
(1, '2024-04-13', 3.2),
(3, '2024-04-10', 2.0),
(3, '2024-04-11', 2.5),
(3, '2024-04-12', 2.2),
(3, '2024-04-13', 2.8),
(5, '2024-04-10', 2.8),
(5, '2024-04-11', 3.5),
(5, '2024-04-12', 3.0),
(5, '2024-04-13', 3.2),
(6, '2024-04-10', 2.0),
(6, '2024-04-11', 2.3),
(6, '2024-04-12', 2.5),
(6, '2024-04-13', 2.7),
(7, '2024-04-10', 2.5),
(7, '2024-04-11', 3.0),
(7, '2024-04-12', 2.7),
(7, '2024-04-13', 3.2),
(8, '2024-04-10', 2.0),
(8, '2024-04-11', 2.5),
(8, '2024-04-12', 2.2),
(8, '2024-04-13', 2.8),
(9, '2024-04-10', 2.8),
(9, '2024-04-11', 3.5),
(9, '2024-04-12', 3.0),
(9, '2024-04-13', 3.2),
(10, '2024-04-10', 2.0),
(10, '2024-04-11', 2.3),
(10, '2024-04-12', 2.5),
(10, '2024-04-13', 2.7);


INSERT INTO Project_Team_3.dbo.WaterLog (User_id, [Date], AmountOfWater)
VALUES 
(11, '2024-04-10', 3.0),
(11, '2024-04-11', 3.5),
(11, '2024-04-12', 2.8),
(11, '2024-04-13', 2.9),
(12, '2024-04-10', 2.5),
(12, '2024-04-11', 2.7),
(12, '2024-04-12', 2.6),
(12, '2024-04-13', 2.7);

select * from Project_Team_3.dbo.WaterLog;


--Insert data into ActivityLog Table

INSERT INTO Project_Team_3.dbo.ActivityLog (User_id, ActivityDescription, Duration, CaloriesBurned, Date)
VALUES
(1, 'Morning Jog', '01:30:00', 450.00, '2024-04-10'),
(1, 'Weightlifting', '01:45:00', 500.00, '2024-04-11'),
(1, 'Yoga', '01:00:00', 250.00, '2024-04-12'),
(1, 'Swimming', '02:00:00', 600.00, '2024-04-13');

-- Ash Pura's activity logs
INSERT INTO Project_Team_3.dbo.ActivityLog (User_id, ActivityDescription, Duration, CaloriesBurned, Date)
VALUES
(3, 'Cycling', '02:30:00', 550.00, '2024-04-10'),
(3, 'Running', '01:30:00', 400.00, '2024-04-11'),
(3, 'Dancing', '01:15:00', 300.00, '2024-04-12'),
(3, 'Hiking', '03:30:00', 700.00, '2024-04-13');

-- harry Puttar's activity logs
INSERT INTO Project_Team_3.dbo.ActivityLog (User_id, ActivityDescription, Duration, CaloriesBurned, Date)
VALUES
(5, 'Morning Walk', '01:00:00', 200.00, '2024-04-10'),
(5, 'Cycling', '01:30:00', 350.00, '2024-04-11'),
(5, 'Yoga', '01:00:00', 250.00, '2024-04-12'),
(5, 'Swimming', '02:30:00', 600.00, '2024-04-13');

-- angilina marry's activity logs
INSERT INTO Project_Team_3.dbo.ActivityLog (User_id, ActivityDescription, Duration, CaloriesBurned, Date)
VALUES
(6, 'Running', '01:45:00', 475.00, '2024-04-10'),
(6, 'Dancing', '01:00:00', 300.00, '2024-04-11'),
(6, 'Weightlifting', '01:30:00', 500.00, '2024-04-12'),
(6, 'Yoga', '00:45:00', 200.00, '2024-04-13');

-- yash gupta's activity logs
INSERT INTO Project_Team_3.dbo.ActivityLog (User_id, ActivityDescription, Duration, CaloriesBurned, Date)
VALUES
(7, 'Swimming', '01:30:00', 450.00, '2024-04-10'),
(7, 'Cycling', '02:00:00', 500.00, '2024-04-11'),
(7, 'Running', '01:15:00', 400.00, '2024-04-12'),
(7, 'Dancing', '01:45:00', 550.00, '2024-04-13');

-- jagga daku's activity logs
INSERT INTO Project_Team_3.dbo.ActivityLog (User_id, ActivityDescription, Duration, CaloriesBurned, Date)
VALUES
(8, 'Weightlifting', '02:00:00', 600.00, '2024-04-10'),
(8, 'Running', '01:30:00', 450.00, '2024-04-11'),
(8, 'Yoga', '01:15:00', 350.00, '2024-04-12'),
(8, 'Cycling', '02:30:00', 700.00, '2024-04-13');

-- manu pund's activity logs
INSERT INTO Project_Team_3.dbo.ActivityLog (User_id, ActivityDescription, Duration, CaloriesBurned, Date)
VALUES
(9, 'Dancing', '01:30:00', 400.00, '2024-04-10'),
(9, 'Hiking', '03:00:00', 600.00, '2024-04-11'),
(9, 'Swimming', '02:00:00', 500.00, '2024-04-12'),
(9, 'Running', '01:45:00', 450.00, '2024-04-13');

-- sarika hegde's activity logs
INSERT INTO Project_Team_3.dbo.ActivityLog (User_id, ActivityDescription, Duration, CaloriesBurned, Date)
VALUES
(10, 'Yoga', '01:00:00', 250.00, '2024-04-10'),
(10, 'Cycling', '01:30:00', 350.00, '2024-04-11'),
(10, 'Running', '01:15:00', 400.00, '2024-04-12'),
(10, 'Hiking', '02:30:00', 600.00, '2024-04-13');

-- neha patil's activity logs
INSERT INTO Project_Team_3.dbo.ActivityLog (User_id, ActivityDescription, Duration, CaloriesBurned, Date)
VALUES
(11, 'Morning Walk', '01:00:00', 200.00, '2024-04-10'),
(11, 'Dancing', '01:30:00', 300.00, '2024-04-11'),
(11, 'Weightlifting', '01:45:00', 500.00, '2024-04-12'),
(11, 'Swimming', '02:00:00', 600.00, '2024-04-13');

-- prady sharma's activity logs
INSERT INTO Project_Team_3.dbo.ActivityLog (User_id, ActivityDescription, Duration, CaloriesBurned, Date)
VALUES
(12, 'Cycling', '02:30:00', 550.00, '2024-04-10'),
(12, 'Running', '01:30:00', 400.00, '2024-04-11'),
(12, 'Hiking', '01:15:00', 300.00, '2024-04-12'),
(12, 'Dancing', '03:30:00', 700.00, '2024-04-13');

--Insert into Transaction table
INSERT INTO Project_Team_3.dbo.TransactionTable (User_id, Subscription_id, Payment_method, Status, [Date])
VALUES
(1, 101, 'Credit Card', 1, '01/01/2023'),
(3, 102, 'Debit Card', 1, '02/01/2023'),
(5, 103, 'PayPal', 1, '03/01/2023'),
(6, 104, 'Credit Card', 1, '04/01/2023'),
(7, 105, 'Debit Card', 1, '05/01/2023'),
(8, 106, 'PayPal', 1, '06/01/2023'),
(9, 107, 'Credit Card', 1, '07/01/2023'),
(10, 108, 'Debit Card', 1, '08/01/2023'),
(11, 109, 'PayPal', 1, '09/01/2023'),
(12, 110, 'Credit Card', 1, '10/01/2023');

--Insert into Subscription Table
INSERT INTO Project_Team_3.dbo.Subscription (Subscription_type_id, User_id, Transaction_id, Status)
VALUES
(1, 1, 1011, 1),   
(2, 3, 1012, 1),   
(3, 5, 1013, 1),   
(4, 6, 1014, 1),   
(1, 7, 1015, 1),   
(2, 8, 1016, 1),   
(3, 9, 1017, 1),   
(4, 10, 1018, 1),  
(1, 11, 1019, 1),  
(2, 12, 1020, 1);  


--Creating View for Progress Report

IF EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[FullProgressReportView]'))
    DROP VIEW [dbo].[FullProgressReportView];


CREATE VIEW [dbo].[FullProgressReportView] AS
SELECT 
    g.User_id,
    u.FName AS FirstName,
    u.LName AS LastName,
    g.Goal_id,
    g.Target_date,
    SUM(a.CaloriesBurned) AS Calories_burned,
    SUM(fi.Serving_size * f.Calories) AS Calories_consumed
FROM 
    Project_Team_3.dbo.Users u
JOIN 
    Project_Team_3.dbo.Goal g ON u.User_id = g.User_id
LEFT JOIN 
    Project_Team_3.dbo.ActivityLog a ON u.User_id = a.User_id
LEFT JOIN 
    Project_Team_3.dbo.NutritionalLog nl ON u.User_id = nl.User_id
LEFT JOIN 
    Project_Team_3.dbo.FoodItem fi ON nl.Nutri_log_id = fi.Nutri_log_id
LEFT JOIN 
    Project_Team_3.dbo.Food f ON fi.Food_id = f.Food_id
GROUP BY 
    g.User_id, 
    u.FName, 
    u.LName, 
    g.Goal_id, 
    g.Target_date;


SELECT * FROM [dbo].[FullProgressReportView];

--Creating View for SUbscription status
CREATE VIEW dbo.ActiveSubscriptionsView AS
SELECT 
    u.User_id,
    u.FName AS 'First Name',
    u.LName AS 'Last Name',
    u.Email_id AS 'Email',
    s.Subscription_id AS 'Subscription ID',
    s.Subscription_type_id AS 'Subscription Type ID',
    s.Transaction_id AS 'Transaction ID',
    s.StartDate AS 'Start Date',
    s.EndDate AS 'End Date',
    CASE 
        WHEN s.Status = 1 THEN 'Active' 
        ELSE 'Inactive' 
    END AS 'Subscription Status'
FROM 
    dbo.Subscription s
INNER JOIN 
    dbo.Users u ON s.User_id = u.User_id
WHERE 
    s.Status = 1 AND (s.EndDate IS NULL OR s.EndDate > GETDATE());
   
select * from dbo.ActiveSubscriptionsView asv;




   

   




