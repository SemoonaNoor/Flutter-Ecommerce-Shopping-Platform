# ENCore 🛍️  
A high-performance, cross-platform e-commerce application built with **Flutter**, tailored for the **lifestyle and fandom merchandise** niche.  
Features a sleek **Glassmorphism UI**, fluid **micro-animations**, and a robust **administrative backend**.  

> 📱 Created for the Mobile Application Development Semester Project  
> 🎓 University of the Punjab, Gujranwala Campus

---

## 📸 Preview

### inside the documentation

---

## ✨ Key Features

### 👤 User Features
- **Secure Authentication**: Powered by Firebase Auth with real-time state monitoring  
- **Dynamic Product Catalog**: 55+ unique SKUs (JJK, EN-, ORV merchandise) with category filtering and search  
- **Immersive Detail Views**: Hero animations and 5-star customer review system  
- **Stateful Shopping Cart**: Real-time price calculation and quantity management  
- **Custom Theming**: Toggle between "Deep Navy" Dark Mode and "Soft Pink" Light Mode with persistent state  

### 🛡️ Administrative Features
- **Role-Based Access Control (RBAC)**: Admin detection via email domain logic (`@admin.com`)  
- **Inventory Oversight**: Restricted panel for product monitoring and simulated editing  
- **Conditional UI**: Admin-specific AppBars and drawer links  

### 🎨 Design & UX
- **Glassmorphism UI**: Frosted-glass effect using `BoxDecoration` and opacity  
- **Responsive Layout**: Adaptive grid (2 columns for Mobile, 3 for Tablet, 4 for Desktop)  
- **Micro-Animations**: Smooth 60fps transitions via `TweenAnimationBuilder` and `CurvedAnimation`  

---

## 🛠️ Technical Architecture

- **Frontend**: Flutter 3.x (Dart)  
- **Backend**: Firebase Authentication  
- **State Management**: Reactive `setState` with structured Models  
- **Navigation**: `MaterialPageRoute` with `AuthGate` stream listening  
- **UI Components**: Custom Slivers, Hero Widgets, Animated Switchers  

---

## 📂 File Structure

```text
lib/
├── main.dart              # Core application logic & UI screens
├── firebase_options.dart  # Firebase configuration

assets/
└── appimages/             # High-res product photography & banners
```

---

## 🚀 Installation & Setup

```bash
# Clone the repository
git clone https://github.com/YourUsername/ENCore-Ecomm-App.git

# Install dependencies
flutter pub get

# Firebase Configuration
# - Create a Firebase project
# - Enable Email/Password Authentication
# - Run flutterfire configure to link your project

# Run the app
flutter run
```

---

## 🧪 Admin Credentials (Demo)

To access the Admin Control Center, use an email ending in `@admin.com`  
  
The app will automatically unlock administrative privileges.

---

## 👤 Author

**Semoona Noor**  
BIT22024 – Department of Information Technology  
University of the Punjab, Gujranwala Campus

---

## 📜 License

This project is licensed under the **MIT License** – see the LICENSE file for details.
