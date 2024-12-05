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
        INSERT INTO customer (username, password, first_name, last_name, membership_type) VALUES (p_username, crypt(p_password, gen_salt('bf')), p_first_name, p_last_name, 1); -- Default membership
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
UPDATE CUSTOMER PERSONAL INFO FUNCTION
*****************************************************************************************/
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


/****************************************************************************************
GET CUSTOMER DETAILS FUNCTION
*****************************************************************************************/
CREATE OR REPLACE FUNCTION get_membership_details(p_username VARCHAR)
    RETURNS TABLE (
                      loyalty_points INTEGER,
                      discount_rate DECIMAL(3, 2),
                      membership_status VARCHAR,
                      shipping_discount DECIMAL(3, 2)
                  ) AS $$
BEGIN
    RETURN QUERY
        SELECT c.loyalty_points,
               t.discount_rate AS discount_rate,
               t.type_name AS membership_status,
               t.shipping_discount_rate AS shipping_discount
        FROM customer c
                 LEFT JOIN membership_type t ON c.membership_type = t.type_id
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
DECLARE
    customer_wishlist_id INTEGER;
BEGIN
    -- Get or create the wishlist for the customer
    SELECT w.wishlist_id INTO customer_wishlist_id
    FROM wishlist w
    WHERE w.customer_id = p_customer_id;

    IF NOT FOUND THEN
        INSERT INTO wishlist (customer_id) VALUES (p_customer_id) RETURNING wishlist_id INTO customer_wishlist_id;
    END IF;

    -- Add the book to the wishlist
    INSERT INTO wishlist_item (wishlist_id, book_id)
    VALUES (customer_wishlist_id, p_book_id)
    ON CONFLICT (wishlist_id, book_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql;


/****************************************************************************************
REMOVE BOOK FROM WISHLIST FUNCTION
*****************************************************************************************/
CREATE OR REPLACE FUNCTION remove_book_from_wishlist(
    p_customer_id INTEGER,
    p_book_id INTEGER
) RETURNS VOID AS $$
DECLARE
    customer_wishlist_id INTEGER;
BEGIN
    -- Get the wishlist ID for the customer
    SELECT wishlist_id INTO customer_wishlist_id
    FROM wishlist
    WHERE customer_id = p_customer_id;

    -- Remove the book from the wishlist
    DELETE FROM wishlist_item
    WHERE wishlist_id = customer_wishlist_id AND book_id = p_book_id;
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
    JOIN wishlist_item wi ON w.wishlist_id = wi.wishlist_id
    JOIN book b ON wi.book_id = b.book_id
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
    new_rank INTEGER;
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
    IF current_points >= 76 THEN
        new_rank := 4;
    ELSIF current_points >= 51 THEN
        new_rank := 3;
    ELSIF current_points >= 26 THEN
        new_rank := 2;
    ELSE
        new_rank := 1;
    END IF;

    -- Update the rank
    UPDATE customer
    SET membership_type = new_rank
    WHERE customer_id = p_customer_id;
END;
$$ LANGUAGE plpgsql;



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
    max_quantity INTEGER;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM shopping_cart WHERE shopping_cart.customer_id = p_customer_id) THEN
        SELECT create_new_cart(p_customer_id);
    END IF;

    SELECT cart_id INTO customer_cart FROM shopping_cart WHERE shopping_cart.customer_id = p_customer_id;

    IF EXISTS (SELECT 1 FROM shopping_cart_item WHERE shopping_cart_item.cart_id = customer_cart AND shopping_cart_item.book_id = p_book_id) THEN
        RAISE EXCEPTION 'Book already in cart.';
    end if;

    SELECT coalesce(get_book_branch_stock(p_book_id, c.branch_id), 0) INTO max_quantity FROM customer c WHERE c.customer_id = p_customer_id;

    IF max_quantity <> 0 THEN
        SELECT price INTO book_price FROM book WHERE book_id = p_book_id;

        INSERT INTO shopping_cart_item (cart_id, book_id, quantity, price)
        VALUES (customer_cart, p_book_id, LEAST(p_book_quantity, max_quantity), book_price);
    END IF;
END;
$$ LANGUAGE plpgsql;

/****************************************************************************************
REMOVE BOOK FROM CUSTOMER CART FUNCTION
*****************************************************************************************/
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

/****************************************************************************************
DELETE CUSTOMER CART FUNCTION
*****************************************************************************************/
CREATE OR REPLACE FUNCTION delete_customer_cart(
    p_customer_id INTEGER
) RETURNS VOID AS $$
DECLARE
    cart_item RECORD;
BEGIN
    FOR cart_item IN SELECT * FROM get_customer_cart(p_customer_id) LOOP
        PERFORM remove_book_from_customer_cart(p_customer_id, cart_item.book_id);
        end loop;
    DELETE FROM shopping_cart
    WHERE customer_id = p_customer_id;
--     COMMIT;
END;
$$ LANGUAGE plpgsql;

/****************************************************************************************
UPDATE BOOK QUANTITY IN CUSTOMER CART FUNCTION
*****************************************************************************************/
CREATE OR REPLACE FUNCTION get_customer_cart_total(p_customer_id INTEGER)
RETURNS TABLE (
    total MONEY,
    discount MONEY,
    total_price MONEY
) AS $$
DECLARE
    TOTAL MONEY;
    DISCOUNT MONEY;
BEGIN
    SELECT sum(i.price*i.quantity) INTO TOTAL
    FROM shopping_cart c
    JOIN shopping_cart_item i ON c.cart_id = i.cart_id
    WHERE c.customer_id =  p_customer_id;

    SELECT TOTAL*t.discount_rate INTO DISCOUNT
    FROM shopping_cart c
    JOIN customer u ON c.customer_id = u.customer_id
    JOIN membership_type t ON t.type_id = u.membership_type
    WHERE c.customer_id =  p_customer_id;

    RETURN QUERY
    SELECT TOTAL, DISCOUNT, TOTAL - DISCOUNT
    FROM shopping_cart c
    WHERE c.customer_id = p_customer_id;
END;
$$ LANGUAGE plpgsql;

/****************************************************************************************
ADD CATEGORY TO BOOK FUNCTION
*****************************************************************************************/
CREATE OR REPLACE FUNCTION add_category_to_book(
    p_book_id INTEGER,
    p_category_id INTEGER
) RETURNS VOID AS $$
BEGIN
    INSERT INTO book_category (book_id, category_id)
    VALUES (p_book_id, p_category_id)
    ON CONFLICT (book_id, category_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

/****************************************************************************************
REMOVE CATEGORY FROM BOOK FUNCTION
*****************************************************************************************/
CREATE OR REPLACE FUNCTION remove_category_from_book(
    p_book_id INTEGER,
    p_category_id INTEGER
) RETURNS VOID AS $$
BEGIN
    DELETE FROM book_category
    WHERE book_id = p_book_id AND category_id = p_category_id;
END;
$$ LANGUAGE plpgsql;

/****************************************************************************************
GET BOOK CATEGORIES FUNCTION
*****************************************************************************************/
CREATE OR REPLACE FUNCTION get_book_categories(p_book_id INTEGER)
RETURNS TABLE (
    category_id INTEGER,
    category_name VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT c.category_id, c.category_name
    FROM book_category bc
    JOIN category c ON bc.category_id = c.category_id
    WHERE bc.book_id = p_book_id;
END;
$$ LANGUAGE plpgsql;

/****************************************************************************************
GET BOOK STOCK FUNCTION
*****************************************************************************************/
CREATE OR REPLACE FUNCTION get_book_stock(p_book_id INTEGER)
RETURNS TABLE (
    store_name VARCHAR,
    address TEXT,
    phone_number VARCHAR,
    email VARCHAR,
    manager_name VARCHAR,
    hours_of_operation VARCHAR,
    quantity INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT sl.store_name, sl.address, sl.phone_number, sl.email, sl.manager_name, sl.hours_of_operation, si.quantity
    FROM store_location sl
    JOIN store_inventory si ON sl.location_id = si.location_id
    WHERE si.book_id = p_book_id;
END;
$$ LANGUAGE plpgsql;

/****************************************************************************************
GET BOOK LOCATION STOCK FUNCTION
*****************************************************************************************/
CREATE OR REPLACE FUNCTION get_book_branch_stock(p_book_id INTEGER, p_branch_id INTEGER)
RETURNS INTEGER AS $$
DECLARE
    stock INTEGER;
BEGIN
    SELECT si.quantity INTO stock
    FROM store_location sl
    JOIN store_inventory si ON sl.location_id = si.location_id
    WHERE si.book_id = p_book_id AND si.location_id = p_branch_id LIMIT 1;
    RETURN stock;
END;
$$ LANGUAGE plpgsql;

/****************************************************************************************
CHECK STOCK QUANTITY FUNCTION
*****************************************************************************************/
CREATE OR REPLACE FUNCTION check_stock_quantity(
    p_location_id INTEGER,
    p_book_id INTEGER,
    p_quantity INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    available_quantity INTEGER;
BEGIN
    SELECT quantity INTO available_quantity
    FROM store_inventory
    WHERE location_id = p_location_id AND book_id = p_book_id;

    IF available_quantity >= p_quantity THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

/****************************************************************************************
COMPLETE PURCHASE FUNCTION
*****************************************************************************************/
CREATE OR REPLACE FUNCTION complete_purchase(
    p_customer_id INTEGER,
    p_payment_method INTEGER,
    p_branch_id INTEGER
) RETURNS VOID AS $$
DECLARE
    CART_ITEM record;
    new_order_id INTEGER;
    cart_total MONEY;
BEGIN
    SELECT create_new_order(p_customer_id, p_branch_id) INTO new_order_id;

    SELECT total_price FROM get_customer_cart_total(p_customer_id) INTO cart_total;

    FOR CART_ITEM IN SELECT * FROM get_customer_cart(p_customer_id) LOOP
        PERFORM update_book_stock_branch(CART_ITEM.book_id, p_branch_id, CART_ITEM.quantity);
        INSERT INTO order_item (order_id, book_id, quantity, price) VALUES (new_order_id, CART_ITEM.book_id, CART_ITEM.quantity, CART_ITEM.total_price);
    end loop;

    INSERT INTO payment (order_id, payment_method, amount, payment_date) VALUES (new_order_id, p_payment_method, cart_total, current_timestamp);

    PERFORM delete_customer_cart(p_branch_id);
    PERFORM update_customer_points_and_rank(p_customer_id);
END;
$$ LANGUAGE plpgsql;

/****************************************************************************************
CREATE NEW ORDER FUNCTION
*****************************************************************************************/
CREATE OR REPLACE FUNCTION create_new_order(
    p_customer_id INTEGER,
    p_branch_id INTEGER)
RETURNS INTEGER AS $$
DECLARE
    order_total MONEY;
    branch_name TEXT;
    new_order_id INTEGER;
BEGIN

    SELECT total_price INTO order_total FROM get_customer_cart_total(p_customer_id);

    SELECT store_name INTO branch_name FROM store_location WHERE location_id = p_branch_id;

    INSERT INTO orders (customer_id, order_date, total_price, status, shipping_address, delivery_date)
    VALUES (
            p_customer_id, CURRENT_TIMESTAMP, order_total,
            'Processing', branch_name, CURRENT_TIMESTAMP + INTERVAL '1' DAY);

    SELECT order_id INTO new_order_id FROM orders WHERE customer_id = p_customer_id ORDER BY order_date desc LIMIT 1;

    RETURN new_order_id;
END;
$$ LANGUAGE plpgsql;



/****************************************************************************************
UPDATE BOOK STOCK FUNCTION
*****************************************************************************************/
CREATE OR REPLACE FUNCTION update_book_stock_branch(
    p_book_id INTEGER,
    p_branch_id INTEGER,
    p_quantity INTEGER
) RETURNS VOID AS $$
DECLARE
    new_qty INTEGER;
BEGIN
    SELECT coalesce(get_book_branch_stock(p_book_id, p_branch_id) - p_quantity, 0) INTO new_qty;
    IF new_qty = 0 THEN
        DELETE FROM store_inventory WHERE location_id = p_branch_id AND book_id = p_book_id;
        RETURN;
    end if;
    UPDATE store_inventory SET quantity = new_qty WHERE location_id = p_branch_id AND book_id = p_book_id;
END;
$$ LANGUAGE plpgsql;


/****************************************************************************************
GET CUSTOMER BRANCH FUNCTION
*****************************************************************************************/
CREATE OR REPLACE FUNCTION get_customer_branch(
    p_customer_id INTEGER
) RETURNS TABLE (
    branch_id INTEGER,
    branch_name VARCHAR(50)
) AS $$
BEGIN
    RETURN QUERY SELECT s.location_id, s.store_name FROM store_location s
    JOIN customer c ON c.customer_id = p_customer_id
    WHERE s.location_id = c.branch_id;
END;
$$ LANGUAGE plpgsql;

/****************************************************************************************
UPDATE CUSTOMER BRANCH FUNCTION
*****************************************************************************************/
CREATE OR REPLACE FUNCTION update_customer_branch(
    p_customer_id INTEGER,
    p_branch_id INTEGER
) RETURNS VOID AS $$
BEGIN
    PERFORM delete_customer_cart(p_customer_id);

    UPDATE customer SET branch_id = p_branch_id WHERE customer_id = p_customer_id;
--     COMMIT;
END;
$$ LANGUAGE plpgsql;


/****************************************************************************************
GET CUSTOMER CART
*****************************************************************************************/
CREATE OR REPLACE FUNCTION get_customer_orders(p_customer_id INTEGER)
RETURNS TABLE (
    order_id INTEGER,
    order_date TIMESTAMP WITH TIME ZONE,
    total_price MONEY,
    shipping_address TEXT,
    delivery_date TIMESTAMP WITH TIME ZONE,
    status VARCHAR(50),
    book_id INTEGER,
    quantity INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT o.order_id, o.order_date, o.total_price, o.shipping_address, o.delivery_date, o.status, oi.book_id, oi.quantity
    FROM orders o
    JOIN public.order_item oi on o.order_id = oi.order_id
    WHERE o.customer_id =  p_customer_id;
END;
$$ LANGUAGE plpgsql;

/****************************************************************************************
GET PAYMENTS
*****************************************************************************************/
CREATE OR REPLACE FUNCTION get_customer_payment(
    p_customer_id INTEGER
)
RETURNS TABLE (
    payment_id INTEGER,
    order_id INTEGER,
    payment_method VARCHAR(50),
    amount MONEY
) AS $$
BEGIN
    RETURN QUERY
    SELECT p.payment_id, o.order_id, pm.method_name, p.amount FROM payment p
    JOIN orders o ON o.order_id = p.order_id
    JOIN payment_method pm ON p.payment_method = pm.method_id
    WHERE o.customer_id = p_customer_id;
END;
$$ LANGUAGE plpgsql;

/****************************************************************************************
GET PAYMENT METHODS
*****************************************************************************************/
CREATE OR REPLACE FUNCTION get_payment_methods()
RETURNS TABLE (
    method_id INTEGER,
    method_name VARCHAR(50)
) AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM payment_method;
END;
$$ LANGUAGE plpgsql;

