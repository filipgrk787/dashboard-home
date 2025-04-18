from flask import Flask, redirect, url_for, session, render_template, jsonify, request
import sqlite3
import os
import secrets
from authlib.integrations.flask_client import OAuth
from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET_KEY", "fallback-secret")
app.wsgi_app = ProxyFix(app.wsgi_app, x_proto=1, x_host=1)

# Secure cookie settings
app.config.update({
    "SESSION_COOKIE_SAMESITE": "Lax",
    "SESSION_COOKIE_SECURE": True
})

# --- OAuth Setup ---
oauth = OAuth(app)

GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID")
GOOGLE_CLIENT_SECRET = os.getenv("GOOGLE_CLIENT_SECRET")

oauth.register(
    name='google',
    client_id=GOOGLE_CLIENT_ID,
    client_secret=GOOGLE_CLIENT_SECRET,
    server_metadata_url='https://accounts.google.com/.well-known/openid-configuration',
    client_kwargs={
        'scope': 'openid email profile'
    }
)

# --- Routes ---
@app.route('/')
def index():
    if 'user' not in session:
        return redirect(url_for('login'))
    return render_template('index.html', user=session['user'])

@app.route('/login')
def login():
    nonce = secrets.token_urlsafe()
    session['nonce'] = nonce
    redirect_uri = url_for('auth', _external=True)
    print("🔍 Flask redirect_uri to Google:", redirect_uri)  # Add this line
    return oauth.google.authorize_redirect(redirect_uri, nonce=nonce)

@app.route('/auth')
def auth():
    try:
        token = oauth.google.authorize_access_token()
        nonce = session.pop('nonce', None)
        user = oauth.google.parse_id_token(token, nonce=nonce)

        # Allowlist check (optional)
        allowed_users = ['filipgrk@gmail.com']
        if user['email'] not in allowed_users:
            return "Unauthorized", 403

        session['user'] = user
        return redirect('/')
    except Exception as e:
        import traceback
        return f"<pre>{traceback.format_exc()}</pre>", 500

@app.route('/logout')
def logout():
    session.pop('user', None)
    return redirect('/')

@app.route('/data')
def data():
    conn = sqlite3.connect('/home/filipgrk/ping_data.db')
    cursor = conn.cursor()
    cursor.execute("SELECT timestamp, success, latency FROM pings ORDER BY timestamp ASC")
    rows = cursor.fetchall()
    conn.close()

    ping_data = []
    total_latency = 0.0
    success_count = 0

    for timestamp, success, latency in rows:
        if success == 1 and latency is not None:
            total_latency += latency
            success_count += 1
            ping_data.append({'timestamp': timestamp, 'latency': latency, 'success': 1})
        else:
            ping_data.append({'timestamp': timestamp, 'latency': None, 'success': 0})

    total_pings = len(rows)
    avg_latency = round(total_latency / success_count, 2) if success_count else 0
    success_rate = round((success_count / total_pings) * 100, 2) if total_pings else 0
    packet_loss = round(100 - success_rate, 2)

    return jsonify({
        "stats": {
            "avg_latency": avg_latency,
            "success_rate": success_rate,
            "packet_loss": packet_loss
        },
        "data": ping_data
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)