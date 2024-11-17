-- Schema for Kinokuniya Bookstore Database

-- 1. Membership Table
CREATE TABLE Membership (
    membership_id SERIAL PRIMARY KEY,
    membership_status VARCHAR(50) CHECK (
        membership_status IN ('Non-Member', 'Regular Member', 'Privilege Card Member')),
    discount_rate DECIMAL(3, 2) DEFAULT 0.00
);

-- 2. Customer Table
CREATE TABLE Customer (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50),
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(50),
    phone_number VARCHAR(15),
    address TEXT,
    date_of_birth DATE,
    loyalty_points INTEGER DEFAULT 0,
    membership_id INTEGER REFERENCES Membership(membership_id) ON DELETE SET NULL
);