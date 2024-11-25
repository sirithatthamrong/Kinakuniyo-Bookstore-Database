from flask import render_template, Response, request, flash, redirect, url_for, session
from sqlalchemy import text

def register_routes(app):
    from app import db

    @app.route('/')
    def home():
        return render_template('home.html')
        
    @app.route('/signup', methods=['GET', 'POST'])
    def signup():
        if request.method == 'POST':
            username = request.form['username']
            password = request.form['password']
            first_name = request.form['first_name']
            last_name = request.form['last_name']

            try:
                # Call PL/pgSQL function to create a new user
                db.session.execute(text("SELECT create_customer(:username, :password, :first_name, :last_name)"),
                                {'username': username, 'password': password, 'first_name': first_name, 'last_name': last_name})
                db.session.commit()
                flash('Account created successfully. Please login.')
                return redirect(url_for('login'))
            except Exception as e:
                db.session.rollback()
                flash(f'Error: {e}')
                return redirect(url_for('signup'))
        return render_template('signup.html')

    @app.route('/login', methods=['GET', 'POST'])
    def login():
        if request.method == 'POST':
            username = request.form['username']
            password = request.form['password']

            # Call PL/pgSQL function to verify login
            result = db.session.execute(text("SELECT verify_customer(:username, :password)"),
                                        {'username': username, 'password': password}).scalar()

            if result:
                # Store username in session
                session['username'] = username
                flash('Login successful!')
                return redirect(url_for('customer_profile')) # Redirect to customer profile page
            else:
                flash('Invalid username or password.')
                return redirect(url_for('login'))
        return render_template('login.html')
    
    @app.route('/logout')
    def logout():
        # Remove user from the session
        session.pop('username', None)
        flash('You have been logged out.')
        return redirect(url_for('home'))

    @app.route('/books')
    def books():
        # Fetch all books from the database
        books = db.session.execute(text("SELECT * FROM book")).fetchall()
        return render_template('books.html', books=books)
    
    @app.route('/books/<int:book_id>')
    def book_detail(book_id):
        # Fetch book details from the database
        book = db.session.execute(text("SELECT * FROM book WHERE book_id = :book_id"), {'book_id': book_id}).fetchone()
        if book:
            return render_template('book_detail.html', book=book)
        else:
            flash('Book not found.', 'danger')
            return redirect(url_for('books'))

    @app.route('/customer/profile')
    def customer_profile():
        # Check if user is logged in
        if 'username' not in session:
            flash("You need to log in first", "warning")
            return redirect(url_for('login'))
        
        username = session['username']
        return render_template('customer_profile.html', username=username)
    
    @app.route('/customer/profile/personal_info', methods=['GET', 'POST'])
    def personal_info():
        # Check if user is logged in
        if 'username' not in session:
            flash("You need to log in first", "warning")
            return redirect(url_for('login'))
        
        username = session['username']

        if request.method == 'POST':
            first_name = request.form['first_name']
            middle_name = request.form['middle_name']
            last_name = request.form['last_name']
            email = request.form['email']
            phone_number = request.form['phone_number']
            address = request.form['address']
            date_of_birth = request.form['date_of_birth']

            try:
                # Call PL/pgSQL function to update customer information
                db.session.execute(text("SELECT update_customer(:username, :first_name, :middle_name, :last_name, :email, :phone_number, :address, :date_of_birth)"),
                                   {'username': username, 'first_name': first_name, 'middle_name': middle_name, 'last_name': last_name, 'email': email, 'phone_number': phone_number, 'address': address, 'date_of_birth': date_of_birth})
                db.session.commit()
                flash('Profile updated successfully.')
                return redirect(url_for('personal_info'))
            except Exception as e:
                db.session.rollback()
                flash(f'Error: {e}')
                return redirect(url_for('personal_info'))

        # Get customer details
        username = session['username']
        customer = db.session.execute(text("SELECT * FROM customer WHERE username = :username"), {'username': username}).fetchone()

        if customer:
            return render_template('personal_info.html', customer=customer)
        else:
            flash('Customer not found.', 'danger')
            return redirect(url_for('customer_profile'))
    
    @app.route('/customer/profile/orders')
    def orders():
        return render_template('orders.html')
    
    @app.route('/customer/profile/wishlist')
    def wishlist():
        return render_template('wishlist.html')
    
    @app.route('/customer/profile/cart')   
    def cart():
        return render_template('cart.html')

    @app.route('/customer/profile/membership')
    def membership():
        # Check if user is logged in
        if 'username' not in session:
            flash("You need to log in first", "warning")
            return redirect(url_for('login'))
        
        username = session['username']

        # Retrieve loyalty points, discount rate, and membership status from the database
        membership_details = db.session.execute(text("SELECT loyalty_points, discount_rate, membership_status, shipping_discount, free_shipping FROM get_membership_details(:username)"),
                                                {'username': username}).fetchone()

        if membership_details:
            return render_template('membership.html', 
                                loyalty_points=membership_details.loyalty_points, 
                                discount_rate=membership_details.discount_rate, 
                                membership_status=membership_details.membership_status,
                                shipping_discount=membership_details.shipping_discount,
                                free_shipping=membership_details.free_shipping)
        else:
            flash('Membership details not found.', 'danger')
            return redirect(url_for('customer_profile'))

    @app.route('/sitemap')
    def sitemap_html():
        return render_template('sitemap.html')

    @app.route('/sitemap.xml')
    def sitemap_xml():
        sitemap_content = """<?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
            <url> <loc>http://localhost:5000/</loc> </url>
            <url> <loc>http://localhost:5000/books</loc> </url>
            <url> <loc>http://localhost:5000/customer/profile</loc> </url>
            <url> <loc>http://localhost:5000/sitemap</loc> </url>
        </urlset>
        """
        return Response(sitemap_content, content_type='application/xml')