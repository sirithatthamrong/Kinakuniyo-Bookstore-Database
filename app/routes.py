from flask import render_template, Response

def register_routes(app):
    @app.route('/')
    def home():
        return render_template('home.html')

    @app.route('/books')
    def books():
        return render_template('books.html')

    @app.route('/customer/profile')
    def customer_profile():
        return render_template('customer_profile.html')

    @app.route('/sitemap')
    def sitemap_html():
        return render_template('sitemap.html')

    @app.route('/sitemap.xml')
    def sitemap_xml():
        sitemap_content = """<?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
            <url>
                <loc>http://localhost:5000/</loc>
                <lastmod>2024-11-17</lastmod>
                <changefreq>daily</changefreq>
                <priority>1.0</priority>
            </url>
            <url>
                <loc>http://localhost:5000/books</loc>
                <lastmod>2024-11-16</lastmod>
                <changefreq>weekly</changefreq>
                <priority>0.8</priority>
            </url>
            <url>
                <loc>http://localhost:5000/customer/profile</loc>
                <lastmod>2024-11-15</lastmod>
                <changefreq>monthly</changefreq>
                <priority>0.6</priority>
            </url>
        </urlset>
        """
        return Response(sitemap_content, content_type='application/xml')
