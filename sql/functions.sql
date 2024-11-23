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


