-- Schema for Kinokuniya Bookstore Database


/****************************************************************************************
CUSTOMER TABLE
*****************************************************************************************/
DROP TABLE IF EXISTS Customer CASCADE;
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
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL,
    membership_type INTEGER REFERENCES Membership_Type DEFAULT 1
);


/****************************************************************************************
MEMBERSHIP TYPE TABLE
*****************************************************************************************/
DROP TABLE IF EXISTS Membership_Type CASCADE;
CREATE TABLE Membership_Type (
    type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL,
    requirement INTEGER,
    discount_rate DECIMAL(3, 2) DEFAULT 0.00,
    shipping_discount_rate DECIMAL(3, 2) DEFAULT 0.00
);


/****************************************************************************************
BOOK TABLE
*****************************************************************************************/
DROP TABLE IF EXISTS Book CASCADE;
CREATE TABLE Book (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    author VARCHAR(100) NOT NULL,
    genre VARCHAR(50),
    publication_date DATE,
    ISBN CHAR(13) UNIQUE NOT NULL,
    price MONEY NOT NULL,
    language VARCHAR(50)
);


/****************************************************************************************
ORDERS TABLE
*****************************************************************************************/
DROP TABLE IF EXISTS Orders CASCADE;
CREATE TABLE Orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES Customer(customer_id) ON DELETE CASCADE,
    order_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    total_price MONEY NOT NULL,
    status VARCHAR(50) NOT NULL CHECK (
        status IN ('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled')
    ),
    shipping_address TEXT,
    delivery_date TIMESTAMP
);


/****************************************************************************************
PAYMENT TABLE
*****************************************************************************************/
DROP TABLE IF EXISTS Payment CASCADE;
CREATE TABLE Payment (
    payment_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES Orders(order_id) ON DELETE CASCADE,
    payment_method VARCHAR(50) NOT NULL CHECK (
        payment_method IN ('Cash', 'Credit Card', 'Debit Card', 'Online Payment', 'Gift Card', 'Points')
    ),
    amount MONEY NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


/****************************************************************************************
ORDER_ITEM TABLE
*****************************************************************************************/
DROP TABLE IF EXISTS Order_Item CASCADE;
CREATE TABLE Order_Item (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES Orders(order_id) ON DELETE CASCADE,
    book_id INTEGER REFERENCES Book(book_id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price MONEY NOT NULL,
    discount MONEY DEFAULT 0
);


/****************************************************************************************
REVIEW TABLE
*****************************************************************************************/
DROP TABLE IF EXISTS Review CASCADE;
CREATE TABLE Review (
    review_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES Customer(customer_id) ON DELETE CASCADE,
    book_id INTEGER REFERENCES Book(book_id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    review_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


/****************************************************************************************
WISHLIST TABLE
*****************************************************************************************/
DROP TABLE IF EXISTS Wishlist CASCADE;
CREATE TABLE Wishlist (
    wishlist_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES Customer(customer_id) ON DELETE CASCADE
);


/****************************************************************************************
WISHLIST_ITEM TABLE
*****************************************************************************************/
DROP TABLE IF EXISTS Wishlist_Item CASCADE;
CREATE TABLE Wishlist_Item (
    wishlist_id INTEGER REFERENCES Wishlist(wishlist_id) ON DELETE CASCADE,
    book_id INTEGER REFERENCES Book(book_id) ON DELETE CASCADE,
    PRIMARY KEY (wishlist_id, book_id)
);


/****************************************************************************************
CATEGORY TABLE
*****************************************************************************************/
DROP TABLE IF EXISTS Category CASCADE;
CREATE TABLE Category (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) UNIQUE NOT NULL
);


/****************************************************************************************
BOOK_CATEGORY TABLE
*****************************************************************************************/
DROP TABLE IF EXISTS Book_Category CASCADE;
CREATE TABLE Book_Category (
    book_id INTEGER REFERENCES Book(book_id) ON DELETE CASCADE,
    category_id INTEGER REFERENCES Category(category_id) ON DELETE CASCADE,
    PRIMARY KEY (book_id, category_id)
);


/****************************************************************************************
SUPPLIER TABLE
*****************************************************************************************/
DROP TABLE IF EXISTS Supplier CASCADE;
CREATE TABLE Supplier (
    supplier_id SERIAL PRIMARY KEY,
    location_id INTEGER REFERENCES Store_Location(location_id) ON DELETE CASCADE,
    supplier_name VARCHAR(100) NOT NULL,
    contact_info TEXT,
    address TEXT,
    email VARCHAR(100)
);


/****************************************************************************************
SHOPPING_CART TABLE (One-to-Many with Customer)
*****************************************************************************************/
DROP TABLE IF EXISTS Shopping_Cart CASCADE;
CREATE TABLE Shopping_Cart (
    cart_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES Customer(customer_id) ON DELETE CASCADE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


/****************************************************************************************
SHOPPING_CART_ITEM TABLE (Many-to-Many between Shopping_Cart and Book)
*****************************************************************************************/
DROP TABLE IF EXISTS Shopping_Cart_Item CASCADE;
CREATE TABLE Shopping_Cart_Item (
    cart_id INTEGER REFERENCES Shopping_Cart(cart_id) ON DELETE CASCADE,
    book_id INTEGER REFERENCES Book(book_id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price MONEY NOT NULL,
    PRIMARY KEY (cart_id, book_id)
);


/****************************************************************************************
STORE_LOCATION TABLE
*****************************************************************************************/
DROP TABLE IF EXISTS Store_Location CASCADE;
CREATE TABLE Store_Location (
    location_id SERIAL PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL,
    address TEXT,
    phone_number VARCHAR(15),
    email VARCHAR(100),
    manager_name VARCHAR(100),
    hours_of_operation VARCHAR(50)
);


/****************************************************************************************
STORE_INVENTORY TABLE (Many-to-Many between Store_Location and Book)
*****************************************************************************************/
DROP TABLE IF EXISTS Store_Inventory CASCADE;
CREATE TABLE Store_Inventory (
    location_id INTEGER REFERENCES Store_Location(location_id) ON DELETE CASCADE,
    book_id INTEGER REFERENCES Book(book_id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    PRIMARY KEY (location_id, book_id)
);