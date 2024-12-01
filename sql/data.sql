-- SQL script for inserting initial/sample data

-- Insert initial data into the Book table
INSERT INTO Book (title, author, genre, publication_date, ISBN, price, language) VALUES
    ('To Kill a Mockingbird', 'Harper Lee', 'Fiction', '1960-07-11', '9780061120084', 10.99, 'English'),
    ('1984', 'George Orwell', 'Dystopian', '1949-06-08', '9780451524935', 9.99, 'English'),
    ('Pride and Prejudice', 'Jane Austen', 'Romance', '1813-01-28', '9781503290563', 8.99, 'English'),
    ('The Great Gatsby', 'F. Scott Fitzgerald', 'Fiction', '1925-04-10', '9780743273565', 10.99, 'English'),
    ('Moby Dick', 'Herman Melville', 'Adventure', '1851-10-18', '9781503280786', 11.99, 'English'),
    ('War and Peace', 'Leo Tolstoy', 'Historical Fiction', '1869-01-01', '9780199232765', 12.99, 'English'),
    ('The Catcher in the Rye', 'J.D. Salinger', 'Fiction', '1951-07-16', '9780316769488', 9.99, 'English'),
    ('The Hobbit', 'J.R.R. Tolkien', 'Fantasy', '1937-09-21', '9780547928227', 14.99, 'English'),
    ('The Lord of the Rings', 'J.R.R. Tolkien', 'Fantasy', '1954-07-29', '9780544003415', 29.99, 'English'),
    ('Harry Potter and the Sorcerer''s Stone', 'J.K. Rowling', 'Fantasy', '1997-06-26', '9780590353427', 24.99, 'English'),
    ('The Da Vinci Code', 'Dan Brown', 'Mystery', '2003-03-18', '9780385504201', 15.99, 'English'),
    ('The Alchemist', 'Paulo Coelho', 'Adventure', '1988-04-15', '9780061122415', 16.99, 'English'),
    ('The Catch-22', 'Joseph Heller', 'Satire', '1961-11-10', '9781451626650', 13.99, 'English'),
    ('Brave New World', 'Aldous Huxley', 'Dystopian', '1932-08-18', '9780060850524', 12.99, 'English'),
    ('The Road', 'Cormac McCarthy', 'Post-apocalyptic', '2006-09-26', '9780307387899', 14.99, 'English'),
    ('The Shining', 'Stephen King', 'Horror', '1977-01-28', '9780307743657', 18.99, 'English'),
    ('The Hunger Games', 'Suzanne Collins', 'Dystopian', '2008-09-14', '9780439023481', 19.99, 'English'),
    ('The Fault in Our Stars', 'John Green', 'Romance', '2012-01-10', '9780525478812', 17.99, 'English'),
    ('Gone Girl', 'Gillian Flynn', 'Thriller', '2012-06-05', '9780307588371', 16.99, 'English'),
    ('The Girl with the Dragon Tattoo', 'Stieg Larsson', 'Mystery', '2005-08-18', '9780307454546', 14.99, 'English'),
    ('The Book Thief', 'Markus Zusak', 'Historical Fiction', '2005-03-14', '9780375842207', 13.99, 'English'),
    ('The Chronicles of Narnia', 'C.S. Lewis', 'Fantasy', '1950-10-16', '9780066238500', 25.99, 'English'),
    ('The Maze Runner', 'James Dashner', 'Dystopian', '2009-10-06', '9780385737951', 18.99, 'English'),
    ('Divergent', 'Veronica Roth', 'Dystopian', '2011-04-25', '9780062024039', 19.99, 'English'),
    ('The Giver', 'Lois Lowry', 'Dystopian', '1993-04-26', '9780544336261', 10.99, 'English');


-- Insert initial data into the Category table
INSERT INTO Category (category_name) VALUES
    ('Fiction'),
    ('Non-Fiction'),
    ('Fantasy'),
    ('Science Fiction'),
    ('Mystery'),
    ('Thriller'),
    ('Horror'),
    ('Romance'),
    ('Historical Fiction'),
    ('Dystopian'),
    ('Adventure'),
    ('Biography'),
    ('Autobiography'),
    ('Self-Help'),
    ('Cooking'),
    ('Travel'),
    ('Science'),
    ('History'),
    ('Art'),
    ('Poetry'),
    ('Religion'),
    ('Philosophy'),
    ('Business'),
    ('Finance'),
    ('Health'),
    ('Fitness'),
    ('Parenting'),
    ('Education'),
    ('Technology'),
    ('Programming');


-- Insert initial data into the Book_Category table
INSERT INTO Book_Category (book_id, category_id) VALUES
    (1, 1), -- To Kill a Mockingbird - Fiction
    (2, 10), -- 1984 - Dystopian
    (3, 8), -- Pride and Prejudice - Romance
    (4, 1), -- The Great Gatsby - Fiction
    (5, 11), -- Moby Dick - Adventure
    (6, 9), -- War and Peace - Historical Fiction
    (7, 1), -- The Catcher in the Rye - Fiction
    (8, 3), -- The Hobbit - Fantasy
    (9, 3), -- The Lord of the Rings - Fantasy
    (10, 3), -- Harry Potter and the Sorcerer's Stone - Fantasy
    (11, 5), -- The Da Vinci Code - Mystery
    (12, 11), -- The Alchemist - Adventure
    (13, 1), -- Catch-22 - Fiction
    (14, 10), -- Brave New World - Dystopian
    (15, 10), -- The Road - Post-apocalyptic
    (16, 7), -- The Shining - Horror
    (17, 10), -- The Hunger Games - Dystopian
    (18, 8), -- The Fault in Our Stars - Romance
    (19, 6), -- Gone Girl - Thriller
    (20, 5), -- The Girl with the Dragon Tattoo - Mystery
    (21, 9), -- The Book Thief - Historical Fiction
    (22, 3), -- The Chronicles of Narnia - Fantasy
    (23, 10), -- The Maze Runner - Dystopian
    (24, 10), -- Divergent - Dystopian
    (25, 10); -- The Giver - Dystopian