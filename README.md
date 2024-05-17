# Nutrition Tracking System - Database Implementation 🍎

## Overview
This repository contains the SQL scripts and documentation for the Nutrition Tracking System, developed by Project Team-3. The purpose of this database is to support users in managing their nutrition and fitness goals by tracking their progress, dietary habits, exercise routines, and consistency. The system provides comprehensive summaries of daily, weekly, and monthly activities, helping users to maintain motivation and achieve healthier lifestyle choices.

## Purpose 🎯
The database is designed to:
- Track individual progress, dietary habits, and exercise routines.
- Provide alerts and reports to encourage users to stick to their goals.
- Analyze data to help users make better health decisions.
- Perform recipe calculations based on serving sizes and nutritional values.
- Ensure the privacy and security of user data through robust security measures.

## Business Problems Addressed 🛠️
- Personalized user experience to increase engagement.
- Tracking streaks and providing reports to motivate users.
- Analyzing data for improving nutrition and exercise habits.
- Facilitating goal tracking and providing achievement reports.
- Calculating nutritional content for recipes and meals.
- Maintaining user confidentiality through data security measures.

## Business Rules 📜
- Each user must have a unique profile.
- Users can create, update, and delete their profiles.
- Users can log food intake and physical activities.
- Each food and activity entry must be associated with the user who logged it.
- The system should calculate nutritional content and track hydration.
- Users should have control over their data and privacy settings.
- The system should provide reports and insights on nutritional intake, physical activity, and health metrics.

## Database Design 🗂️

### Entities and Relationships

#### User 👤
- Represents individuals using the app.
- Related to almost all other entities.
- Relationships: One-to-many with Subscription, Health Goal, Nutritional Profile, Nutritional Log, Activity Log, Water Log, Sleep Log, Progress Reports.

#### Subscription 📝
- Manages subscription plans and status.
- Relationships: Linked to User and Transaction. One-to-one with Subscription Type.

#### Subscription Type 💳
- Defines types of subscriptions.
- Relationship: One-to-many with Subscription.

#### Transaction 💰
- Records details of payments for subscriptions.
- Relationships: Linked to User and Subscription.

#### Health Goal 🥅
- Records user-specific health goals.
- Relationships: Foreign key from User. One-to-one with Goal Type. Related to Progress Reports.

#### Goal Type 🏷️
- Categorizes health goals.
- Relationship: Linked to Health Goal.

#### Nutritional Profile 📊
- Stores users' biometric data.
- Relationship: Linked to User.

#### Nutritional Log 🍽️
- Logs user's food intake.
- Relationships: Linked to User and Food. Related to Meal.

#### Meal 🍔
- Categorizes food intake into meal types.
- Relationship: Linked to Nutritional Log.

#### Food 🥗
- Details food items, including nutritional content.
- Relationship: Linked to Nutritional Log.

#### Food_item 🍱
- Intersection table for many-to-many relation between Food and Nutritional Log.
- Relationships: One-to-many with Food and Nutritional Log.

#### Activity Log 🏃‍♂️
- Tracks physical activities.
- Relationship: Linked to User.

#### Water Log 💧
- Tracks daily water intake.
- Relationship: Linked to User.

#### Sleep Log 💤
- Monitors sleep patterns.
- Relationship: Linked to User.

#### Progress Reports 📈
- Summarizes user progress towards health goals.
- Relationships: Linked to User and Health Goal.

## SQL Scripts 💾
The SQL scripts for creating and populating the database can be found in the `FInal DB implementation 2.sql` file. This file includes the necessary commands to:
- Create tables for each entity.
- Define relationships and constraints.
- Insert initial data for testing and demonstration purposes.

## Getting Started 🚀
To set up the database:
1. Ensure you have MSSQL installed and configured.
2. Run the `FInal DB implementation 2.sql` script in your SQL management tool.
3. Verify the tables and relationships are created as per the design document.

## Usage 🛠️
Once the database is set up, you can:
- Create user profiles.
- Log food intake, physical activities, water intake, and sleep patterns.
- Set and track health goals.
- Generate reports and insights based on logged data.

## Security Measures 🔐
The database implements robust security measures to ensure user data privacy:
- Data encryption.
- Access controls.
- Regular audits.

## Conclusion 🎉
The Nutrition Tracking System database provides a comprehensive solution for managing and tracking nutrition and fitness goals. By following the setup instructions and using the provided SQL scripts, you can implement and utilize this database to help users achieve their health objectives. 

For more details on the design and implementation, refer to the `Team-3-Database _design_doc.pdf`.

---

Feel free to reach out to the project team for any further assistance or queries.

## Team Members 👥
- Suhas K M
- Pradhyumna Soni
- Neha Gopinath
- Ashwini Jayant Puranik
