CREATE EXTENSION IF NOT EXISTS pgcrypto; -- For crypt() and gen_salt() function


/****************************************************************************************
CREATE CUSTOMER FUNCTION
*****************************************************************************************/
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
        INSERT INTO customer (username, password, first_name, last_name, membership_type) VALUES (p_username, crypt(p_password, gen_salt('bf')), p_first_name, p_last_name, 'Regular'); -- Default membership
    END IF;
END;
$$ LANGUAGE plpgsql;


/****************************************************************************************
VERIFY CUSTOMER FUNCTION
*****************************************************************************************/
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


/****************************************************************************************
UPDATE CUSTOMER FUNCTION
*****************************************************************************************/
CREATE OR REPLACE FUNCTION update_customer(
    p_username VARCHAR,
    p_first_name VARCHAR,
    p_middle_name VARCHAR,
    p_last_name VARCHAR,
    p_email VARCHAR,
    p_phone_number VARCHAR,
    p_address TEXT,
    p_date_of_birth DATE,
    p_membership_type VARCHAR
) RETURNS VOID AS $$
BEGIN
    UPDATE customer
    SET first_name = p_first_name,
        middle_name = p_middle_name,
        last_name = p_last_name,
        email = p_email,
        phone_number = p_phone_number,
        address = p_address,
        date_of_birth = p_date_of_birth,
        membership_type = p_membership_type
    WHERE username = p_username;
END;
$$ LANGUAGE plpgsql;


/****************************************************************************************
GET CUSTOMER DETAILS FUNCTION
*****************************************************************************************/
CREATE OR REPLACE FUNCTION get_membership_details(p_username VARCHAR)
    RETURNS TABLE (
                      loyalty_points INTEGER,
                      discount_rate NUMERIC,
                      membership_status VARCHAR,
                      shipping_discount NUMERIC,
                      free_shipping BOOLEAN
                  ) AS $$
BEGIN
    RETURN QUERY
        SELECT c.loyalty_points,
               COALESCE(s.discount_rate, g.discount_rate, p.discount_rate, 0) AS discount_rate,
               c.membership_type AS membership_status,
               COALESCE(g.shipping_discount, 0) AS shipping_discount,
               COALESCE(p.free_shipping, FALSE) AS free_shipping
        FROM customer c
                 LEFT JOIN Silver s ON c.customer_id = s.customer_id
                 LEFT JOIN Gold g ON c.customer_id = g.customer_id
                 LEFT JOIN Platinum p ON c.customer_id = p.customer_id
        WHERE c.username = p_username;
END;
$$ LANGUAGE plpgsql;


/****************************************************************************************
ADD OR UPDATE REVIEW FUNCTION
*****************************************************************************************/
CREATE OR REPLACE FUNCTION add_or_update_review(
    p_customer_id INTEGER,
    p_book_id INTEGER,
    p_rating INTEGER,
    p_review_text TEXT
) RETURNS VOID AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM review WHERE customer_id = p_customer_id AND book_id = p_book_id) THEN
        -- Update existing review
        UPDATE review
        SET rating = p_rating,
            review_text = p_review_text,
            review_date = CURRENT_TIMESTAMP
        WHERE customer_id = p_customer_id AND book_id = p_book_id;
    ELSE
        -- Insert new review
        INSERT INTO review (customer_id, book_id, rating, review_text, review_date)
        VALUES (p_customer_id, p_book_id, p_rating, p_review_text, CURRENT_TIMESTAMP);
    END IF;
END;
$$ LANGUAGE plpgsql;


/****************************************************************************************
ADD BOOK TO WISHLIST FUNCTION
*****************************************************************************************/
CREATE OR REPLACE FUNCTION add_book_to_wishlist(
    p_customer_id INTEGER,
    p_book_id INTEGER
) RETURNS VOID AS $$
BEGIN
    INSERT INTO wishlist (customer_id, book_id)
    VALUES (p_customer_id, p_book_id);
END;
$$ LANGUAGE plpgsql;


/****************************************************************************************
REMOVE BOOK FROM WISHLIST FUNCTION
*****************************************************************************************/
CREATE OR REPLACE FUNCTION remove_book_from_wishlist(
    p_customer_id INTEGER,
    p_book_id INTEGER
) RETURNS VOID AS $$
BEGIN
    DELETE FROM wishlist
    WHERE customer_id = p_customer_id AND book_id = p_book_id;
END;
$$ LANGUAGE plpgsql;


/****************************************************************************************
GET CUSTOMER WISHLIST FUNCTION
*****************************************************************************************/
CREATE OR REPLACE FUNCTION get_customer_wishlist(p_username VARCHAR)
RETURNS TABLE (
    book_id INTEGER,
    title VARCHAR,
    author VARCHAR,
    genre VARCHAR,
    price MONEY
) AS $$
BEGIN
    RETURN QUERY
    SELECT b.book_id, b.title, b.author, b.genre, b.price
    FROM wishlist w
    JOIN book b ON w.book_id = b.book_id
    WHERE w.customer_id = (SELECT customer_id FROM customer WHERE username = p_username);
END;
$$ LANGUAGE plpgsql;


/****************************************************************************************
UPDATE CUSTOMER LOYALTY POINTS AND RANK FUNCTION
*****************************************************************************************/
CREATE OR REPLACE FUNCTION update_customer_points_and_rank(p_customer_id INTEGER)
RETURNS VOID AS $$
DECLARE
    current_points INTEGER;
    new_rank VARCHAR;
BEGIN
    -- Increase points by 5
    UPDATE customer
    SET loyalty_points = loyalty_points + 5
    WHERE customer_id = p_customer_id;

    -- Get the updated points
    SELECT loyalty_points INTO current_points
    FROM customer
    WHERE customer_id = p_customer_id;

    -- Determine the new rank based on points
    IF current_points <= 25 THEN
        new_rank := 'Regular';
    ELSIF current_points <= 50 THEN
        new_rank := 'Silver';
    ELSIF current_points <= 70 THEN
        new_rank := 'Gold';
    ELSE
        new_rank := 'Platinum';
    END IF;

    -- Update the rank
    UPDATE customer
    SET membership_type = new_rank
    WHERE customer_id = p_customer_id;
GET CUSTOMER CART FUNCTION



/****************************************************************************************
GET CUSTOMER CART
*****************************************************************************************/
CREATE OR REPLACE FUNCTION get_customer_cart(p_customer_id INTEGER)
RETURNS TABLE (
    book_id INTEGER,
    title VARCHAR,
    author VARCHAR,
    genre VARCHAR,
    quantity INTEGER,
    price MONEY,
    total_price MONEY
) AS $$
BEGIN
    RETURN QUERY
    SELECT i.book_id, b.title, b.author, b.genre, i.quantity, i.price, i.price*i.quantity
    FROM shopping_cart c
    JOIN shopping_cart_item i ON c.cart_id = i.cart_id
    JOIN book b on b.book_id = i.book_id
    WHERE c.customer_id =  p_customer_id;
END;
$$ LANGUAGE plpgsql;

/****************************************************************************************
CREATE NEW CUSTOMER CART
*****************************************************************************************/
CREATE OR REPLACE FUNCTION create_new_cart(
    p_customer_id INTEGER)
RETURNS VOID AS $$
BEGIN
    INSERT INTO shopping_cart (customer_id, created_date)
    VALUES (p_customer_id, CURRENT_TIMESTAMP);
END;
$$ LANGUAGE plpgsql;

/****************************************************************************************
ADD ITEM TO CUSTOMER CART FUNCTION
*****************************************************************************************/
CREATE OR REPLACE FUNCTION add_book_to_customer_cart(
    p_customer_id INTEGER,
    p_book_id INTEGER,
    p_book_quantity INTEGER)
RETURNS VOID AS $$
DECLARE
    customer_cart INTEGER;
    book_price MONEY;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM shopping_cart WHERE shopping_cart.customer_id = p_customer_id) THEN
        SELECT create_new_cart(p_customer_id);
    END IF;

    SELECT cart_id INTO customer_cart FROM shopping_cart WHERE shopping_cart.customer_id = p_customer_id;

    IF EXISTS (SELECT 1 FROM shopping_cart_item WHERE shopping_cart_item.cart_id = customer_cart AND shopping_cart_item.book_id = p_book_id) THEN
        RAISE EXCEPTION 'Book already in cart.';
    end if;

    SELECT price INTO book_price FROM book WHERE book_id = p_book_id;

    INSERT INTO shopping_cart_item (cart_id, book_id, quantity, price)
    VALUES (customer_cart, p_book_id, p_book_quantity, book_price);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION remove_book_from_customer_cart(
    p_customer_id INTEGER,
    p_book_id INTEGER
) RETURNS VOID AS $$
DECLARE
    customer_cart INTEGER;
BEGIN
    SELECT cart_id INTO customer_cart FROM shopping_cart WHERE shopping_cart.customer_id = p_customer_id;
    DELETE FROM shopping_cart_item
    WHERE cart_id = customer_cart AND book_id = p_book_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_customer_cart_total(p_customer_id INTEGER)
RETURNS TABLE (
    total MONEY
) AS $$
BEGIN
    RETURN QUERY
    SELECT sum(i.price*i.quantity)
    FROM shopping_cart c
    JOIN shopping_cart_item i ON c.cart_id = i.cart_id
    WHERE c.customer_id =  p_customer_id;
END;
$$ LANGUAGE plpgsql;