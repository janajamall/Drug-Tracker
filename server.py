from flask import Flask, request, jsonify, send_from_directory
import sqlite3
import os

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = r"C:\Users\<user>\Desktop\Drug-Tracker" #Replace with the valid path

# Database file path
DATABASE = r"C:\Users\<user>\Desktop\Drug-Tracker\users.db" #Replace with the valid path

def get_user_by_wallet(wallet_address):
    conn = sqlite3.connect(DATABASE)
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT * FROM users WHERE wallet = ?", (wallet_address ,))
        user = cursor.fetchall()
        if user:
            print(user[0][1])
            return user[0][1]
        else:
            return 'non registered user'
    finally:
        conn.close()

@app.route('/')
def serve_index():
    return send_from_directory(app.config['UPLOAD_FOLDER'], 'index.html')


@app.route('/connect-wallet', methods=['POST'])
def connect_wallet():
    data = request.json
    wallet_address = data.get('wallet_address')
    if not wallet_address:
        return jsonify({"error": "Wallet address is required"}), 400

    type = get_user_by_wallet(wallet_address)
    if type == 'non registered user':
        return jsonify({"error": "User not found"}), 404

    return jsonify({"message": "User fetched successfully", "type": type})

if __name__ == '__main__':
    app.run(debug=True)
