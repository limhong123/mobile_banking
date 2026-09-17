# Mobile Banking App

A full-stack mobile banking solution featuring a Flutter mobile application, a Python backend, and a React admin frontend.

## Project Structure

This repository is organized into three main components:

- **`mobile_banking_app/`**: The cross-platform mobile application built with Flutter. It includes features for authentication, money transfers, transaction history, and KYC (Know Your Customer) using facial recognition and document scanning.
- **`backend/`**: The RESTful API backend built with Python. It handles business logic, database operations, Firebase integration, and handles file uploads for KYC processes.
- **`admin-frontend/`**: The web-based admin dashboard built with React, Vite, and Tailwind CSS. It is used by administrators to monitor transactions, manage users, and verify KYC documents.

## Prerequisites

Before you begin, ensure you have the following installed:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (for the mobile app)
- [Python 3.8+](https://www.python.org/downloads/) (for the backend)
- [Node.js & npm/yarn](https://nodejs.org/) (for the admin frontend)

## Getting Started

### 1. Backend Setup
```bash
cd backend
python -m venv venv
# Activate the virtual environment
# Windows: venv\Scripts\activate
# Mac/Linux: source venv/bin/activate
pip install -r requirements.txt
```
*(Note: Ensure your `firebase-service-account.json` is placed in the backend directory. This file is ignored by Git for security.)*

### 2. Admin Frontend Setup
```bash
cd admin-frontend
npm install
npm run dev
```

### 3. Mobile App Setup
```bash
cd mobile_banking_app
flutter pub get
flutter run
```

## Features
* **Secure Authentication** (PIN, OTP)
* **KYC Verification** (Liveness detection, ID scanning)
* **Cash Transfers & QR Payments** (KHQR)
* **Transaction History & Receipts**
* **Admin Dashboard**

## Security Warning
Never commit sensitive files like `firebase-service-account.json` or `.env` files to this repository. They have already been added to the `.gitignore`.
