# LoginForm

The LoginForm is a graphical user interface (GUI) form implemented in Free Pascal with the Lazarus Component Library (LCL). It provides functionality for user registration, login, account updates, and account deletion. The form interacts with a PostgreSQL database to store user information and uses the BCrypt hashing algorithm for secure password storage.

# Dependencies

## The LoginForm relies on the following dependencies:

Lazarus Component Library (LCL): The LCL is a cross-platform library that provides components and controls for building GUI applications in Free Pascal.

ZeosLib: ZeosLib is a database connectivity and access library for various database systems. In this code, it is used to connect to and interact with a PostgreSQL database.

BCrypt: BCrypt is a password hashing algorithm that provides a secure way to store and verify passwords. It is used in this code to hash and compare passwords.
-> https://github.com/viniciussanchez/bcrypt

# Usage

## The LoginForm provides the following functionality:

User Registration: Clicking the "Register" button opens a dialog where the user can enter a username and password. The username and password are validated for length and complexity. If the username is available and the password meets the requirements, the user is registered and added to the PostgreSQL database.

User Login: Clicking the "Login" button verifies the entered username and password against the stored values in the database. If the credentials are valid, a success message is displayed, and the login attempts counter for the user is reset. If the credentials are invalid, an appropriate message is displayed, and the login attempts counter is incremented. After ten failed login attempts, the account is blocked.

Account Update: Clicking the "Change Account" button allows the user to update their account information. The user must provide the current password to authenticate. If the password is valid, a dialog prompts the user to enter a new username and password. The new username is checked for availability, and the new password is validated for length and complexity. If all conditions are met, the account information is updated in the database.

Account Deletion: Clicking the "Delete Account" button deletes the user's account from the database. The user must provide the current password to authenticate and confirm the account deletion.

Exiting the Application: Clicking the "Exit" button closes the application.

# Database Configuration

The LoginForm connects to a PostgreSQL database for storing user information. The database connection settings are configured in the SetupDatabaseConnection procedure. 

## By default, the following settings are used:

    Protocol: PostgreSQL
    User: admin
    Password: admin
    HostName: localhost
    Port: 5432
    Database: login

Please modify these settings according to your database configuration before using the application.

# Security Considerations

## The LoginForm employs several security measures to protect user information:

BCrypt Password Hashing: User passwords are hashed using the BCrypt algorithm before being stored in the database. BCrypt is a one-way hashing algorithm that adds a salt and multiple iterations to the password hash, making it computationally expensive to crack passwords even if the database is compromised.

Login Attempts Limit: The application imposes a limit of ten failed login attempts for each user. If the limit is reached, the account is blocked to prevent brute-force attacks.

Secure Database Connection: The LoginForm establishes a secure connection to the PostgreSQL database using the specified connection settings.

It's important to note that while these measures enhance security, they do not guarantee absolute protection.

# PostgreSQL Database Setup

The "login" database has a single table called "users" with columns for the user ID, username, hashed password, and login attempt count.

Note: The password column is VARCHAR(60) to accommodate the BCrypt hashed password, which typically results in a string of 60 characters.
	
You can now modify the LoginForm's database connection settings according to your PostgreSQL configuration and start using the application. :)
