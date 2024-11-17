-- Schema for Kinokuniya Bookstore Database

-- 1. Membership Table
CREATE TABLE Membership (
    membership_id SERIAL PRIMARY KEY,
    membership_status VARCHAR(50) UNIQUE NOT NULL CHECK (
        membership_status IN ('Non-Member', 'Regular Member', 'Privilege Card Member')
        ),
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

-- 3. Book Table
CREATE TABLE Book (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    author VARCHAR(100) NOT NULL,
    genre VARCHAR(50),
    publication_date DATE,
    ISBN CHAR(13) UNIQUE NOT NULL,
    price MONEY NOT NULL,
    language VARCHAR(50),
    stock_quantity INTEGER DEFAULT 0 CHECK (stock_quantity >= 0)
);

-- 4. Orders Table
CREATE TABLE Orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES Customer(customer_id) ON DELETE CASCADE,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_price MONEY NOT NULL,
    status VARCHAR(50) NOT NULL CHECK (
        status IN ('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled')
    ),
    pay_method VARCHAR(50) NOT NULL CHECK (
        pay_method IN ('Cash', 'Credit Card', 'Debit Card', 'Online Payment', 'Gift Card', 'Points')
    ),
    shipping_address TEXT,
    delivery_date TIMESTAMP
);

-- 5. Order_Item Table (Many-to-Many between Order and Book)
CREATE TABLE Order_Item (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES Orders(order_id) ON DELETE CASCADE,
    book_id INTEGER REFERENCES Book(book_id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price MONEY NOT NULL,
    discount MONEY DEFAULT 0
);

-- 6. Review Table
CREATE TABLE Review (
    review_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES Customer(customer_id) ON DELETE CASCADE,
    book_id INTEGER REFERENCES Book(book_id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    review_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Wishlist Table
CREATE TABLE Wishlist (
    wishlist_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES Customer(customer_id) ON DELETE CASCADE,
    wishlist_name VARCHAR(50),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. Wishlist_Item Table (Many-to-Many between Wishlist and Book)
CREATE TABLE Wishlist_Item (
    wishlist_id INTEGER REFERENCES Wishlist(wishlist_id) ON DELETE CASCADE,
    book_id INTEGER REFERENCES Book(book_id) ON DELETE CASCADE,
    PRIMARY KEY (wishlist_id, book_id)
);

-- 9. Category Table
CREATE TABLE Category (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) UNIQUE NOT NULL
);

-- 10. Book_Category Table (Many-to-Many between Book and Category)
CREATE TABLE Book_Category (
    book_id INTEGER REFERENCES Book(book_id) ON DELETE CASCADE,
    category_id INTEGER REFERENCES Category(category_id) ON DELETE CASCADE,
    PRIMARY KEY (book_id, category_id)
);

-- 11. Supplier Table
CREATE TABLE Supplier (
    supplier_id SERIAL PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL,
    contact_info TEXT,
    address TEXT,
    email VARCHAR(100)
);

-- 12. Inventory Table
CREATE TABLE Inventory (
    inventory_id SERIAL PRIMARY KEY,
    book_id INTEGER REFERENCES Book(book_id) ON DELETE CASCADE,
    supplier_id INTEGER REFERENCES Supplier(supplier_id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    purchase_price MONEY NOT NULL,
    purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reorder_level INTEGER DEFAULT 0 -- Minimum quantity to trigger reorder
);

-- 13. Shopping_Cart Table
CREATE TABLE Shopping_Cart (
    cart_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES Customer(customer_id) ON DELETE CASCADE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount MONEY NOT NULL
);

-- 14. Shopping_Cart_Item Table (Many-to-Many between Shopping_Cart and Book)
CREATE TABLE Shopping_Cart_Item (
    cart_id INTEGER REFERENCES Shopping_Cart(cart_id) ON DELETE CASCADE,
    book_id INTEGER REFERENCES Book(book_id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price MONEY NOT NULL,
    PRIMARY KEY (cart_id, book_id)
);

-- 15. Store_Location Table
CREATE TABLE Store_Location (
    location_id SERIAL PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL,
    address TEXT,
    phone_number VARCHAR(15),
    email VARCHAR(100),
    manager_name VARCHAR(100),
    hours_of_operation VARCHAR(50)
);

-- 16. Store_Inventory Table (Many-to-Many between Store_Location and Book)
CREATE TABLE Store_Inventory (
    location_id INTEGER REFERENCES Store_Location(location_id) ON DELETE CASCADE,
    book_id INTEGER REFERENCES Book(book_id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    PRIMARY KEY (location_id, book_id)
);