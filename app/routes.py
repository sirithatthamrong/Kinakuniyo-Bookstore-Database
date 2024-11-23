from flask import render_template, Response
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

    @app.route('/books')
    def books():
        return render_template('books.html')

    @app.route('/customer/profile')
    def customer_profile():
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
