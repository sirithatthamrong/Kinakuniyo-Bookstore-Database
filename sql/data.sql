-- SQL script for inserting initial/sample data

-- Membership Types
INSERT INTO Membership (membership_status, discount_rate) VALUES
    ('Regular', 0), -- Default membership
    ('Silver', 0.05),
    ('Gold', 0.1),
    ('Platinum', 0.15);