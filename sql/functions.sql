CREATE EXTENSION IF NOT EXISTS pgcrypto; -- For crypt() and gen_salt() function


-- Create a new customer
CREATE OR REPLACE FUNCTION create_customer(
    p_username VARCHAR,
    p_password VARCHAR,
    p_first_name VARCHAR,
    p_last_name VARCHAR
) RETURNS VOID AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM customer WHERE customer.username = p_username) THEN
        RAISE EXCEPTION 'Username already exists.';
    ELSE
        INSERT INTO customer (username, password, first_name, last_name) VALUES (p_username, crypt(p_password, gen_salt('bf')), p_first_name, p_last_name);
    END IF;
END;
$$ LANGUAGE plpgsql;


-- Verify customer credentials
CREATE OR REPLACE FUNCTION  verify_customer(
    p_username character varying,
    p_password character varying
) RETURNS BOOLEAN AS $$
DECLARE
    stored_password TEXT; -- Variable to hold the hashed password from the database
BEGIN
    -- Retrieve the hashed password for the given username
    SELECT password INTO stored_password
    FROM customer
    WHERE customer.username = p_username;

    -- If no matching username is found, return FALSE
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    -- Compare the provided password with the stored hashed password
    IF stored_password = crypt(p_password, stored_password) THEN
        RETURN TRUE; -- Password is correct
    ELSE
        RETURN FALSE; -- Password is incorrect
    END IF;
END;
$$ LANGUAGE plpgsql;


-- Update customer information
CREATE OR REPLACE FUNCTION update_customer(
    p_username VARCHAR,
    p_first_name VARCHAR,
    p_middle_name VARCHAR,
    p_last_name VARCHAR,
    p_email VARCHAR,
    p_phone_number VARCHAR,
    p_address TEXT,
    p_date_of_birth DATE
) RETURNS VOID AS $$
BEGIN
    UPDATE customer
    SET first_name = p_first_name,
        middle_name = p_middle_name,
        last_name = p_last_name,
        email = p_email,
        phone_number = p_phone_number,
        address = p_address,
        date_of_birth = p_date_of_birth
    WHERE username = p_username;
END;
$$ LANGUAGE plpgsql;


-- Get membership details
CREATE OR REPLACE FUNCTION get_membership_details(p_username VARCHAR)
    RETURNS TABLE (
                      loyalty_points INTEGER,
                      discount_rate NUMERIC,
                      membership_status VARCHAR
                  ) AS $$
BEGIN
    RETURN QUERY
        SELECT c.loyalty_points, m.discount_rate, m.membership_status
        FROM customer c
                 JOIN membership m ON c.membership_id = m.membership_id
        WHERE c.username = p_username;
END;
$$ LANGUAGE plpgsql;


-- Reset loyalty points for all customers
CREATE OR REPLACE FUNCTION reset_loyalty_points()
    RETURNS VOID AS $$
BEGIN
    UPDATE customer
    SET loyalty_points = 0,
        membership_id = 1 -- Reset to Regular membership
    WHERE '1' = '1';
END;
$$ LANGUAGE plpgsql;


-- Update loyalty points and membership status when a book is purchased
CREATE OR REPLACE FUNCTION update_loyalty_points(p_customer_id INTEGER)
    RETURNS VOID AS $$
DECLARE
    current_points INTEGER;
BEGIN
    -- Increase loyalty points by 5
    UPDATE customer
    SET loyalty_points = loyalty_points + 5
    WHERE customer_id = p_customer_id;

    -- Get the updated loyalty points
    SELECT loyalty_points INTO current_points
    FROM customer
    WHERE customer_id = p_customer_id;

    -- Update membership status based on loyalty points
    IF current_points <= 25 THEN
        UPDATE customer
        SET membership_id = 1 -- Regular
        WHERE customer_id = p_customer_id;
    ELSIF current_points <= 50 THEN
        UPDATE customer
        SET membership_id = 2 -- Silver
        WHERE customer_id = p_customer_id;
    ELSIF current_points <= 75 THEN
        UPDATE customer
        SET membership_id = 3 -- Gold
        WHERE customer_id = p_customer_id;
    ELSE
        UPDATE customer
        SET membership_id = 4 -- Platinum
        WHERE customer_id = p_customer_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

