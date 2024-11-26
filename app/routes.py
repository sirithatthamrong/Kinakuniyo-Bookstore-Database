from flask import render_template, Response, request, flash, redirect, url_for, session
from sqlalchemy import text

def register_routes(app):
    from app import db

    def get_customer_id(username):
        customer = db.session.execute(text("SELECT customer_id FROM customer WHERE username = :username"), {'username': username}).fetchone()
        return customer.customer_id if customer else None

    def require_login():
        if 'username' not in session:
            flash("You need to log in first", "warning")
            return redirect(url_for('login'))
        return session['username']

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

            result = db.session.execute(text("SELECT verify_customer(:username, :password)"),
                                        {'username': username, 'password': password}).scalar()

            if result:
                session['username'] = username
                flash('Login successful!')
                return redirect(url_for('customer_profile'))
            else:
                flash('Invalid username or password.')
                return redirect(url_for('login'))
        return render_template('login.html')

    @app.route('/logout')
    def logout():
        session.pop('username', None)
        flash('You have been logged out.')
        return redirect(url_for('home'))

    @app.route('/books')
    def books():
        books = db.session.execute(text("SELECT * FROM book")).fetchall()
        return render_template('books.html', books=books)

    @app.route('/books/<int:book_id>', methods=['GET'])
    def book_detail(book_id):
        book = db.session.execute(text("SELECT * FROM book WHERE book_id = :book_id"), {'book_id': book_id}).fetchone()
        reviews = db.session.execute(text("SELECT * FROM review WHERE book_id = :book_id ORDER BY review_date DESC"), {'book_id': book_id}).fetchall()

        if book:
            return render_template('book_detail.html', book=book, reviews=reviews)
        else:
            flash('Book not found.', 'danger')
            return redirect(url_for('books'))

    @app.route('/books/<int:book_id>/add_review', methods=['POST'])
    def add_review(book_id):
        username = require_login()

        rating = request.form['rating']
        review_text = request.form['review_text']
        customer_id = get_customer_id(username)

        if not customer_id:
            flash('Customer not found.', 'danger')
            return redirect(url_for('books'))

        try:
            db.session.execute(text("SELECT add_or_update_review(:customer_id, :book_id, :rating, :review_text)"),
                               {'customer_id': customer_id, 'book_id': book_id, 'rating': rating, 'review_text': review_text})
            db.session.commit()
            flash('Review submitted successfully.')
            return redirect(url_for('book_detail', book_id=book_id))
        except Exception as e:
            db.session.rollback()
            flash(f'Error: {e}')
            return redirect(url_for('book_detail', book_id=book_id))

    @app.route('/customer/profile')
    def customer_profile():
        username = require_login()
        
        return render_template('customer_profile.html', username=username)

    @app.route('/customer/profile/personal_info', methods=['GET', 'POST'])
    def personal_info():
        username = require_login()

        if request.method == 'POST':
            first_name = request.form['first_name']
            middle_name = request.form['middle_name']
            last_name = request.form['last_name']
            email = request.form['email']
            phone_number = request.form['phone_number']
            address = request.form['address']
            date_of_birth = request.form['date_of_birth']

            try:
                db.session.execute(text("SELECT update_customer(:username, :first_name, :middle_name, :last_name, :email, :phone_number, :address, :date_of_birth)"),
                                   {'username': username, 'first_name': first_name, 'middle_name': middle_name, 'last_name': last_name, 'email': email, 'phone_number': phone_number, 'address': address, 'date_of_birth': date_of_birth})
                db.session.commit()
                flash('Profile updated successfully.')
                return redirect(url_for('personal_info'))
            except Exception as e:
                db.session.rollback()
                flash(f'Error: {e}')
                return redirect(url_for('personal_info'))

        customer = db.session.execute(text("SELECT * FROM customer WHERE username = :username"), {'username': username}).fetchone()

        if customer:
            return render_template('personal_info.html', customer=customer)
        else:
            flash('Customer not found.', 'danger')
            return redirect(url_for('customer_profile'))

    @app.route('/customer/profile/wishlist', methods=['GET'])
    def wishlist():
        username = require_login()

        wishlist = db.session.execute(text("SELECT * FROM get_customer_wishlist(:username)"), {'username': username}).fetchall()
        return render_template('wishlist.html', wishlist=wishlist)

    @app.route('/customer/profile/wishlist/add_book/<int:book_id>', methods=['POST'])
    def add_book_to_wishlist(book_id):
        username = require_login()

        customer_id = get_customer_id(username)
        if not customer_id:
            flash('Customer not found.', 'danger')
            return redirect(url_for('books'))

        try:
            db.session.execute(text("SELECT add_book_to_wishlist(:customer_id, :book_id)"),
                               {'customer_id': customer_id, 'book_id': book_id})
            db.session.commit()
            flash('Book added to wishlist successfully.')
            return redirect(url_for('books'))
        except Exception as e:
            db.session.rollback()
            flash(f'Error: {e}')
            return redirect(url_for('books'))

    @app.route('/customer/profile/wishlist/remove_book/<int:book_id>', methods=['POST'])
    def remove_book_from_wishlist(book_id):
        username = require_login()

        customer_id = get_customer_id(username)
        if not customer_id:
            flash('Customer not found.', 'danger')
            return redirect(url_for('wishlist'))

        try:
            db.session.execute(text("SELECT remove_book_from_wishlist(:customer_id, :book_id)"),
                               {'customer_id': customer_id, 'book_id': book_id})
            db.session.commit()
            flash('Book removed from wishlist successfully.')
            return redirect(url_for('wishlist'))
        except Exception as e:
            db.session.rollback()
            flash(f'Error: {e}')
            return redirect(url_for('wishlist'))

    @app.route('/customer/profile/orders')
    def orders():
        return render_template('orders.html')

    @app.route('/customer/profile/cart')
    def cart():

        username = require_login()


        customer_id = get_customer_id(username)

        cart = db.session.execute(text("SELECT * FROM get_customer_cart(:customer_id)"), {'customer_id': customer_id}).fetchall()
        print(cart)
        return render_template('cart.html', cart=cart)

    @app.route('/customer/profile/cart/add_book/<int:book_id>', methods=['POST'])    
    def add_book_to_cart(book_id):
        username = require_login()

        customer_id = get_customer_id(username)
        if not customer_id:
            flash('Customer not found.', 'danger')
            return redirect(url_for('books'))

        try:
            cart = db.session.execute(text("SELECT * FROM get_customer_cart(:customer_id)"), {'customer_id': customer_id}).fetchall()
            if not cart:
                db.session.execute(text("SELECT create_new_cart(:customer_id)"), {'customer_id': customer_id}).fetchall()
                db.session.commit()
                print("New cart created!")
            db.session.execute(text("SELECT add_book_to_customer_cart(:customer_id, :book_id)"), {'customer_id': customer_id, 'book_id': book_id}).fetchall()
            db.session.commit()
            flash('Book added to cart successfully.')
            return redirect(url_for('cart'))
        except Exception as e:
            db.session.rollback()
            flash(f'Error: {e}')
            return redirect(url_for('books'))
    
    @app.route('/customer/profile/cart/remove_book/<int:book_id>', methods=['POST'])
    def remove_book_from_cart(book_id):
        username = require_login()

        customer_id = get_customer_id(username)
        if not customer_id:
            flash('Customer not found.', 'danger')
            return redirect(url_for('home'))

        try:
            db.session.execute(text("SELECT remove_book_from_customer_cart(:customer_id, :book_id)"),
                               {'customer_id': customer_id, 'book_id': book_id})
            db.session.commit()
            flash('Book removed from cart successfully.')
            return redirect(url_for('cart'))
        except Exception as e:
            db.session.rollback()
            flash(f'Error: {e}')
            return redirect(url_for('cart'))
        
    @app.route('/customer/profile/membership')
    def membership():
        username = require_login()

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