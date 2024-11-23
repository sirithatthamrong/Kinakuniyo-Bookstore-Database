from flask import render_template, Response, request, flash, redirect, url_for, session
from sqlalchemy import text

def register_routes(app):
    from app import db

    @app.route('/')
    def home():
        return render_template('home.html')
    
    @app.route('/test_db')
    def test_db():
        try:
            # Perform a simple query to test the connection
            result = db.session.execute(text('SELECT 1'))
            return 'Database connection successful!'
        except Exception as e:
            return f'Database connection failed: {e}'
        
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
        return render_template('books.html')

    @app.route('/customer/profile')
    def customer_profile():
        # Check if user is logged in
        if 'username' not in session:
            flash("You need to log in first", "warning")
            return redirect(url_for('login'))
    
        return render_template('customer_profile.html')
    
    @app.route('/customer/profile/personal_info')
    def personal_info():
        return render_template('personal_info.html')
    
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
        return render_template('membership.html')

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
