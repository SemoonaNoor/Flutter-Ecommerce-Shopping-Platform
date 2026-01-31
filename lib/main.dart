import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

/// ===================== MAIN =====================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const EncoreRoot());
}

/// ===================== ROOT + THEME =====================

class EncoreRoot extends StatefulWidget {
  const EncoreRoot({super.key});

  @override
  State<EncoreRoot> createState() => _EncoreRootState();
}

class _EncoreRootState extends State<EncoreRoot> {
  ThemeMode _themeMode = ThemeMode.dark; // default dark

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode =
          (_themeMode == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ENCORE',
      themeMode: _themeMode,
      theme: ThemeData(
        //fontFamily: 'Trajan Pro',
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pinkAccent,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F4F5),
        cardColor: Colors.white,
      ),
      darkTheme: ThemeData(
        //fontFamily: 'Trajan Pro',
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pinkAccent,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF050816),
        cardColor: const Color(0xFF111827),
      ),
      home: AuthGate(
        themeMode: _themeMode,
        onThemeToggle: _toggleTheme,
      ),
    );
  }
}

/// ===================== AUTH GATE =====================

class AuthGate extends StatelessWidget {
  final ThemeMode themeMode;
  final void Function(bool isDark) onThemeToggle;

  const AuthGate({
    super.key,
    required this.themeMode,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasData && snap.data != null) {
          final email = snap.data!.email ?? '';
          final bool isAdmin =
              email.toLowerCase().endsWith('adminsam@encore.com');

          return WelcomeScreen(
            themeMode: themeMode,
            onThemeToggle: onThemeToggle,
            isAdmin: isAdmin,
          );
        }

        return AuthScreen(themeMode: themeMode);
      },
    );
  }
}

/// ===================== AUTH SCREEN (LOGIN / SIGNUP) =====================

class AuthScreen extends StatefulWidget {
  final ThemeMode themeMode;
  const AuthScreen({super.key, required this.themeMode});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _loading = false;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  late AnimationController _controller;
  late Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _cardFade = CurvedAnimation(parent: _controller, curve: Curves.easeInQuart);
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? "Auth Error")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor =
        _isLogin ? const Color(0xFF7C4DFF) : const Color(0xFFFF4081);
    final String titleText =
        _isLogin ? 'Welcome Back User!' : 'Join the Squad!';
    final String buttonText = _isLogin ? 'SECURE LOGIN' : 'CREATE ACCOUNT';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isLogin
                ? [const Color(0xFF050816), const Color(0xFF1E1B4B)]
                : [const Color(0xFF1E1B4B), const Color(0xFF4A148C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: FadeTransition(
              opacity: _cardFade,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Icon(_isLogin ? Icons.lock_person : Icons.person_add,
                      color: primaryColor, size: 60),
                  const SizedBox(height: 10),
                  Text(titleText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        _buildStyledField(
                            controller: _emailCtrl,
                            label: 'Email',
                            icon: Icons.email,
                            color: primaryColor),
                        const SizedBox(height: 20),
                        _buildStyledField(
                            controller: _passCtrl,
                            label: 'Password',
                            icon: Icons.key,
                            isPass: true,
                            color: primaryColor),
                        const SizedBox(height: 30),
                        _loading
                            ? CircularProgressIndicator(color: primaryColor)
                            : SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                  ),
                                  onPressed: _submit,
                                  child: Text(buttonText,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                        _isLogin
                            ? "New Here? Create an Account and Enjoy"
                            : "Already have one? Login Certified Cool person ^^",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: primaryColor)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStyledField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      bool isPass = false,
      required Color color}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: color),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: color, width: 2)),
      ),
    );
  }
}

/// ===================== WELCOME SCREEN (ORIGINAL AESTHETIC) =====================

class WelcomeScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final void Function(bool isDark) onThemeToggle;
  final bool isAdmin;

  const WelcomeScreen({
    super.key,
    required this.themeMode,
    required this.onThemeToggle,
    required this.isAdmin,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> logoScale;
  late Animation<double> titleSlide;
  late Animation<double> buttonFade;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    logoScale = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
    );
    titleSlide = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
    );
    buttonFade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void enterShop() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EncoreApp(
          themeMode: widget.themeMode,
          onThemeToggle: widget.onThemeToggle,
          isAdmin: widget.isAdmin,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeMode == ThemeMode.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF1E1B4B), Color(0xFF312E81)]
                : const [Color(0xFFFF80AB), Color(0xFF7C4DFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          // 1. ADDED SingleChildScrollView HERE
          child: SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  ScaleTransition(
                    scale: logoScale,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.style, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            widget.isAdmin
                                ? 'ADMIN CONTROL · EN‑Core'
                                : 'EN‑Core',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. REPLACED 'Expanded' with 'SizedBox' to prevent the stripes
                  SizedBox(
                    height: 450, // This keeps the banner large but safe
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/appimages/banner.jpg',
                            fit: BoxFit.cover,
                          ),
                          Container(
                            color: Colors.black.withOpacity(0.55),
                          ),
                          Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24.0),
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.2),
                                  end: Offset.zero,
                                ).animate(titleSlide),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text(
                                      'Welcome, to Shop at EN‑CORE',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'EN‑, JJK, ORV and many more – all in one tiny shop.\n'
                                      'Warning: may cause impulsive “add to cart” moments.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: buttonFade,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: const Text(
                          'Enter shop',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        onPressed: enterShop,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16), // Increased spacing slightly
                  FadeTransition(
                    opacity: buttonFade,
                    child: const Text(
                      'P.S. You can switch to dark/light mode later if the other theme starts blinding your soul.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Bottom padding for scrolling
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ===================== MODELS =====================

class Product {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String description;
  final int price;
  final double rating;
  final String image;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.description,
    required this.price,
    required this.rating,
    required this.image,
  });
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  int get totalPrice => product.price * quantity;
}

class Review {
  final String productId;
  final String userName;
  final String comment;
  final int stars;

  Review({
    required this.productId,
    required this.userName,
    required this.comment,
    required this.stars,
  });
}

class UserProfile {
  String name;
  String email;

  UserProfile({required this.name, required this.email});
}

/// ===================== ROOT APP WITH ADMIN FLAG =====================

class EncoreApp extends StatefulWidget {
  final ThemeMode themeMode;
  final void Function(bool isDark) onThemeToggle;
  final bool isAdmin;

  const EncoreApp({
    super.key,
    required this.themeMode,
    required this.onThemeToggle,
    required this.isAdmin,
  });

  @override
  State<EncoreApp> createState() => _EncoreAppState();
}

class _EncoreAppState extends State<EncoreApp> {
  ThemeMode get themeMode => widget.themeMode;
  void toggleTheme(bool isDark) => widget.onThemeToggle(isDark);

  // ----- In‑memory data -----
  final List<Product> allProducts = [
    const Product(
      id: 'p1',
      name: 'Chibi SatoSugo Keychain',
      brand: 'JJK',
      category: 'JJK Keychain',
      description:
          'A very cute Gojo x Geto Chibi version keychain, perfect to attach with any bags, purse etc. '
          'For Satosugo Lovers, Its a perfect trinket to buy for oneself or as a Birthday Gift.',
      price: 1000,
      rating: 4.9,
      image: 'chibi gojoxgeto keychain.jpg',
    ),
    const Product(
      id: 'p2',
      name: 'DazaixChuyya keychain',
      brand: 'BSD',
      category: 'BSD Keychain',
      description:
          'A perfect CHUYA AND DAZAI trinket to buy for oneself or as a Birthday Gift, now available at ENCore.',
      price: 1000,
      rating: 4.9,
      image: 'dazaixchuyya keychain.jpg',
    ),
    const Product(
      id: 'p3',
      name: 'EN- Circle Keychain',
      brand: 'EN-',
      category: 'EN- Keychain',
      description:
          "Artistic ENHYPEN keychain series. From minimal geometric designs to the 'Fate' concept, these durable acrylic and metal charms are perfect for bags or lightstick customization.",
      price: 1500,
      rating: 4.8,
      image: 'enha circle keychian.jpg',
    ),
    const Product(
      id: 'p4',
      name: 'EN- Fate Keychain',
      brand: 'EN-',
      category: 'EN- Keychain',
      description:
          "Artistic ENHYPEN keychain series. From minimal geometric designs to the 'Fate' concept, these durable acrylic and metal charms are perfect for bags or lightstick customization.",
      price: 1500,
      rating: 4.7,
      image: 'enha fate keychain.jpg',
    ),
    const Product(
      id: 'p5',
      name: 'En- Geometry Keychain',
      brand: 'EN-',
      category: 'EN- Keychain',
      description:
          "Artistic ENHYPEN keychain series. From minimal geometric designs to the 'Fate' concept, these durable acrylic and metal charms are perfect for geometries customization.",
      price: 900,
      rating: 4.6,
      image: 'enha geometry keychain.jpg',
    ),
    const Product(
      id: 'p6',
      name: 'EN- mini lightstick Keychain',
      brand: 'EN-',
      category: 'EN- Keychain',
      description:
          'Artistic ENHYPEN keychain series. From minimal geometric designs to the Fate concept, these durable acrylic and metal charms are perfect for bags or lightstick customization.',
      price: 1200,
      rating: 4.5,
      image: 'enha keychain.jpg',
    ),
    const Product(
      id: 'p7',
      name: 'EN- Star Keychain',
      brand: 'EN-',
      category: 'EN- Keychain',
      description:
          'Artistic ENHYPEN keychain series. From minimal geometric designs to the Fate concept, these durable acrylic and metal charms are perfect for bags or lightstick customization.',
      price: 1200,
      rating: 4.4,
      image: 'enhypen star keychain.jpg',
    ),
    const Product(
      id: 'p8',
      name: 'Gojo x Geto CUTE Chibi Keychain',
      brand: 'JJK',
      category: 'JJK Keychain',
      description:
          'Heartwarming SatoSugu collection celebrating the strongest duo. Features high-gloss acrylic finishes in various themes including Chibi, Kitty, and Fish variants.',
      price: 1500,
      rating: 4.4,
      image: 'gojo and geto keychain.jpg',
    ),
    const Product(
      id: 'p9',
      name: 'Satosugo Kitty Keychain',
      brand: 'JJK',
      category: 'JJK Keychain',
      description:
          'Heartwarming SatoSugu collection celebrating the strongest duo. Features high-gloss acrylic finishes in various themes including Chibi, Kitty, and Fish variants.',
      price: 1500,
      rating: 4.4,
      image: 'gojogeto kitty keychains.jpg',
    ),
    const Product(
      id: 'p10',
      name: 'Gojo x Geto Fish Keychain 01',
      brand: 'JJK',
      category: 'JJK Keychain',
      description:
          'Heartwarming SatoSugu collection celebrating the strongest duo. Features high-gloss acrylic finishes in various themes including Chibi, Kitty, and Fish variants.',
      price: 1200,
      rating: 4.4,
      image: 'gojoxgeto fish keychain.jpg',
    ),
    const Product(
      id: 'p11',
      name: 'Gojo x Geto Fish Keychain 02',
      brand: 'JJK',
      category: 'JJK Keychain',
      description:
          'Heartwarming SatoSugu collection celebrating the strongest duo. Features high-gloss acrylic finishes in various themes including Chibi, Kitty, and Fish variants.',
      price: 1200,
      rating: 4.4,
      image: 'gojoxgeto keychain.jpg',
    ),
    const Product(
      id: 'p12',
      name: 'Gojo x Geto Mini Kittens Keychain',
      brand: 'JJK',
      category: 'JJK Keychain',
      description:
          'Heartwarming SatoSugu collection celebrating the strongest duo. Features high-gloss acrylic finishes in various themes including Chibi, Kitty, and Fish variants.',
      price: 1200,
      rating: 4.4,
      image: 'gojoxgeto kitty keychains.jpg',
    ),
    const Product(
      id: 'p14',
      name: 'SatoSugo Keychain',
      brand: 'JJK',
      category: 'JJK Keychain',
      description:
          'Heartwarming SatoSugu collection celebrating the strongest duo. Features high-gloss acrylic finishes in various themes including Chibi, Kitty, and Fish variants.',
      price: 1200,
      rating: 4.4,
      image: 'gojo and geto keychain.jpg',
    ),
    const Product(
      id: 'p15',
      name: 'Heesung Doll Pl ushie Series 01',
      brand: 'EN-',
      category: 'EN- Plushies',
      description:
          'Elegant Heeseung plush doll. Designed with precision to highlight his Ace features, this high-quality collectible is a must-have for your EN-Core shelf.',
      price: 2200,
      rating: 4.4,
      image: 'heesung doll 01.jpg',
    ),
    const Product(
      id: 'p16',
      name: 'Heesung Doll Plushie Series 02',
      brand: 'EN-',
      category: 'EN- Plushies',
      description:
          'Elegant Heeseung plush doll. Designed with precision to highlight his Ace features, this high-quality collectible is a must-have for your EN-Core shelf.',
      price: 2200,
      rating: 4.4,
      image: 'heesung doll 02.jpg',
    ),
    const Product(
      id: 'p17',
      name: 'Heesung Doll Plushie Series 03',
      brand: 'EN-',
      category: 'EN- Plushies',
      description:
          'Elegant Heeseung plush doll. Designed with precision to highlight his Ace features, this high-quality collectible is a must-have for your EN-Core shelf.',
      price: 2200,
      rating: 4.4,
      image: 'heesung doll 03.jpg',
    ),
    const Product(
      id: 'p18',
      name: 'Hoon Plushie Series 01',
      brand: 'EN-',
      category: 'EN- Plushies',
      description:
          "Versatile Sunghoon plush collection including the rare Vampire and Pink editions. Perfectly captures the Ice Prince's cool and endearing aesthetic",
      price: 2200,
      rating: 4.4,
      image: 'hoon doll pink 01.jpg',
    ),
    const Product(
      id: 'p19',
      name: 'Jake Plsuhie Series 01',
      brand: 'EN-',
      category: 'EN- Plushies',
      description:
          "Premium Jake-inspired plush doll featuring his signature charm. Soft, huggable, and meticulously detailed to capture his iconic look, making it the perfect companion for any ENGENE.",
      price: 2200,
      rating: 4.4,
      image: 'jake doll.jpg',
    ),
    const Product(
      id: 'p20',
      name: 'Jake Plushie Series 02',
      brand: 'EN-',
      category: 'EN- Plushies',
      description:
          "Premium Jake-inspired plush doll featuring his signature charm. Soft, huggable, and meticulously detailed to capture his iconic look, making it the perfect companion for any ENGENE.",
      price: 2200,
      rating: 4.4,
      image: 'jake doll 01.jpg',
    ),
    const Product(
      id: 'p21',
      name: 'Jake Plushie Series 03',
      brand: 'EN-',
      category: 'EN- Plushies',
      description:
          "Premium Jake-inspired plush doll featuring his signature charm. Soft, huggable, and meticulously detailed to capture his iconic look, making it the perfect companion for any ENGENE.",
      price: 2200,
      rating: 4.4,
      image: 'jake doll 02.jpg',
    ),
    const Product(
      id: 'p22',
      name: 'Jay Doll Series 01',
      brand: 'EN-',
      category: 'EN- Plushies',
      description:
          "Stylish Jay-inspired collectible plush. Crafted with high-quality fabric, showcasing his charismatic stage presence in a cute, portable form.",
      price: 2200,
      rating: 4.4,
      image: 'jay doll 02.jpg',
    ),
    const Product(
      id: 'p23',
      name: 'Jay Doll Series 02',
      brand: 'EN-',
      category: 'EN- Plushies',
      description:
          "Stylish Jay-inspired collectible plush. Crafted with high-quality fabric, showcasing his charismatic stage presence in a cute, portable form.",
      price: 2200,
      rating: 4.4,
      image: 'jay doll 03.jpg',
    ),
    const Product(
      id: 'p24',
      name: 'Jay Doll Series 03',
      brand: 'EN-',
      category: 'EN- Plushies',
      description:
          "Stylish Jay-inspired collectible plush. Crafted with high-quality fabric, showcasing his charismatic stage presence in a cute, portable form.",
      price: 2200,
      rating: 4.4,
      image: 'jayy doll 01.jpg',
    ),
    const Product(
      id: 'p25',
      name: 'JJK Anime Keychain',
      brand: 'JJK',
      category: 'JJK Keychain',
      description:
          "A curated variety set of Jujutsu Kaisen character keychains, featuring high-definition prints of your favorite sorcerers on premium acrylic. ",
      price: 1200,
      rating: 4.4,
      image: 'jjk anime keychains.jpg',
    ),
    const Product(
      id: 'p26',
      name: 'Jungwon Doll Series 01',
      brand: 'EN-',
      category: 'EN- Plushies',
      description:
          "Leader Jungwon in plush form. Featuring his adorable 'wonie' expressions and signature style, crafted for maximum durability and cuteness.",
      price: 2200,
      rating: 4.4,
      image: 'jungownie doll 01.jpg',
    ),
    const Product(
      id: 'p27',
      name: 'Jungwon Doll Series 02',
      brand: 'EN-',
      category: 'EN- Plushies',
      description:
          "Leader Jungwon in plush form. Featuring his adorable 'wonie' expressions and signature style, crafted for maximum durability and cuteness.",
      price: 2200,
      rating: 4.4,
      image: 'jungownie doll 02.jpg',
    ),
    const Product(
      id: 'p28',
      name: 'Jungwon Doll Series 03',
      brand: 'EN-',
      category: 'EN- Plushies',
      description:
          "Leader Jungwon in plush form. Featuring his adorable 'wonie' expressions and signature style, crafted for maximum durability and cuteness.",
      price: 2200,
      rating: 4.4,
      image: 'jungwonie doll 03.jpg',
    ),
    const Product(
      id: 'p29',
      name: 'Leebit Series 01',
      brand: 'Leebit',
      category: 'Leebit',
      description:
          "Official-style Leebit character plushies. These high-quality SKZOO-inspired dolls are perfect for display or travel, bringing Lee Know's quirky charm to life.",
      price: 3000,
      rating: 4.9,
      image: 'leebit 01.jpg',
    ),
    const Product(
      id: 'p30',
      name: 'Leebit Series 02',
      brand: 'Leebit',
      category: 'Leebit',
      description:
          "Official-style Leebit character plushies. These high-quality SKZOO-inspired dolls are perfect for display or travel, bringing Lee Know's quirky charm to life.",
      price: 3000,
      rating: 4.9,
      image: 'leebit 02.jpg',
    ),
    const Product(
      id: 'p31',
      name: 'Leebit Series 03',
      brand: 'Leebit',
      category: 'Leebit',
      description:
          "Official-style Leebit character plushies. These high-quality SKZOO-inspired dolls are perfect for display or travel, bringing Lee Know's quirky charm to life.",
      price: 3000,
      rating: 4.9,
      image: 'leebit 03.jpg',
    ),
    const Product(
      id: 'p32',
      name: 'Leebit Series 04',
      brand: 'Leebit',
      category: 'Leebit',
      description:
          "Official-style Leebit character plushies. These high-quality SKZOO-inspired dolls are perfect for display or travel, bringing Lee Know's quirky charm to life.",
      price: 3000,
      rating: 4.9,
      image: 'leebit 04.jpg',
    ),
    const Product(
      id: 'p33',
      name: 'SatoSugo Mini Ver Keychain',
      brand: 'JJk',
      category: 'JJK Keychain',
      description:
          "Heartwarming SatoSugu collection celebrating the strongest duo. Features high-gloss acrylic finishes in various themes including Chibi, Kitty, and Fish variants.",
      price: 3000,
      rating: 4.9,
      image: 'mini gojoxgeto keychain.jpg',
    ),
    const Product(
      id: 'p34',
      name: 'Ni-Ki Doll Series 01',
      brand: 'En-',
      category: 'EN- Plushies',
      description:
          "Adorable Ni-ki plushie series. Includes the special 'Puma' edition, capturing the maknae's powerful yet sweet energy with expert embroidery and soft-touch materials.",
      price: 2300,
      rating: 4.9,
      image: 'ni-ki puma doll.jpg',
    ),
    const Product(
      id: 'p35',
      name: 'Ni-ki Doll Series 02',
      brand: 'EN-',
      category: 'EN- Plushies',
      description:
          "Adorable Ni-ki plushie series. Includes the special 'Puma' edition, capturing the maknae's powerful yet sweet energy with expert embroidery and soft-touch materials.",
      price: 2300,
      rating: 4.9,
      image: 'ni-ki doll 02.jpg',
    ),
    const Product(
      id: 'p36',
      name: 'Ni-Ki Doll Series 03',
      brand: 'EN-',
      category: 'EN- Plushies',
      description:
          "Adorable Ni-ki plushie series. Includes the special 'Puma' edition, capturing the maknae's powerful yet sweet energy with expert embroidery and soft-touch materials.",
      price: 2300,
      rating: 4.9,
      image: 'ni-ki doll 03.jpg',
    ),
    const Product(
      id: 'p37',
      name: 'ORV Duo Doll Set Series 01',
      brand: 'ORV',
      category: 'ORV DOLL SET',
      description:
          "Exclusive Omniscient Reader's Viewpoint (ORV) collectible sets. Featuring Kim Dokja and Yoo Joonghyuk with high-detail craftsmanship that brings the webnovel to reality.",
      price: 4600,
      rating: 4.9,
      image: 'orv dolls 01.jpg',
    ),
    const Product(
      id: 'p38',
      name: 'ORV Duo Doll Set Series 02',
      brand: 'ORV',
      category: 'ORV DOLL SET',
      description:
          "Exclusive Omniscient Reader's Viewpoint (ORV) collectible sets. Featuring Kim Dokja and Yoo Joonghyuk with high-detail craftsmanship that brings the webnovel to reality.",
      price: 4600,
      rating: 4.9,
      image: 'orv doll set 02.jpg',
    ),
    const Product(
      id: 'p39',
      name: 'ORV Duo Doll Set Series 03',
      brand: 'ORV',
      category: 'ORV DOLL SET',
      description:
          "Exclusive Omniscient Reader's Viewpoint (ORV) collectible sets. Featuring Kim Dokja and Yoo Joonghyuk with high-detail craftsmanship that brings the webnovel to reality.",
      price: 4600,
      rating: 4.9,
      image: 'orv doll set 03.jpg',
    ),
    const Product(
      id: 'p40',
      name: 'ORV Duo Doll Set Series 04',
      brand: 'ORV',
      category: 'ORV DOLL SET',
      description:
          "Exclusive Omniscient Reader's Viewpoint (ORV) collectible sets. Featuring Kim Dokja and Yoo Joonghyuk with high-detail craftsmanship that brings the webnovel to reality.",
      price: 4600,
      rating: 4.9,
      image: 'orv doll set 04.jpg',
    ),
    const Product(
      id: 'p41',
      name: 'ORV Duo Doll Set Series 05',
      brand: 'ORV',
      category: 'ORV DOLL SET',
      description:
          "Exclusive Omniscient Reader's Viewpoint (ORV) collectible sets. Featuring Kim Dokja and Yoo Joonghyuk with high-detail craftsmanship that brings the webnovel to reality.",
      price: 4600,
      rating: 4.9,
      image: 'orv doll set 05.jpg',
    ),
    const Product(
      id: 'p42',
      name: 'Enhypen Paranormal Song Keychain',
      brand: 'EN-',
      category: 'EN- Keychain',
      description:
          "Artistic ENHYPEN keychain series. From minimal geometric designs to the 'Fate' concept, these durable acrylic and metal charms are perfect for bags or lightstick customization.",
      price: 1200,
      rating: 4.5,
      image: 'paranormal enha keychain.jpg',
    ),
    const Product(
      id: 'p43',
      name: 'Pink Hair Sunoo Doll Series 01',
      brand: 'EN-',
      category: 'EN- Plusies',
      description:
          "The ultimate Sunoo collection. Features the fan-favorite pink hair variant. Vibrant colors and a sunshine aesthetic that mirrors Sunoo's bright personality.",
      price: 2200,
      rating: 4.9,
      image: 'pink hair sunoo doll.jpg',
    ),
    const Product(
      id: 'p44',
      name: 'SatoSugo Kitten Keychain Ver2',
      brand: 'JJK',
      category: 'JJK Keychain',
      description:
          "Heartwarming SatoSugu collection celebrating the strongest duo. Features high-gloss acrylic finishes in various themes including Chibi, Kitty, and Fish variants.",
      price: 1200,
      rating: 4.5,
      image: 'satosugo kitten keychain.jpg',
    ),
    const Product(
      id: 'p45',
      name: 'SatoSugo Shrinked Keychain',
      brand: 'JJK',
      category: 'JJK Keychain',
      description:
          "Heartwarming SatoSugu collection celebrating the strongest duo. Features high-gloss acrylic finishes in various themes including Chibi, Kitty, and Fish variants.",
      price: 1200,
      rating: 4.5,
      image: 'satosugo shrink kaychain.jpg',
    ),
    const Product(
      id: 'p46',
      name: 'SatoSugo Cute Chibbi Keychain',
      brand: 'JJK',
      category: 'JJK Keychain',
      description:
          "Heartwarming SatoSugu collection celebrating the strongest duo. Features high-gloss acrylic finishes in various themes including Chibi, Kitty, and Fish variants.",
      price: 1200,
      rating: 4.5,
      image: 'satosugu  keychain.jpg',
    ),
    const Product(
      id: 'p47',
      name: 'Sunghoon Doll Series 02',
      brand: 'EN-',
      category: 'EN- Plushie',
      description:
          "Versatile Sunghoon plush collection including the rare 'Vampire' and 'Pink' editions. Perfectly captures the Ice Prince's cool and endearing aesthetic.",
      price: 3200,
      rating: 4.5,
      image: 'sunghoon doll 01.jpg',
    ),
    const Product(
      id: 'p48',
      name: 'Sunghoon Doll Series 03',
      brand: 'EN-',
      category: 'EN- Plushie',
      description:
          "Versatile Sunghoon plush collection including the rare 'Vampire' and 'Pink' editions. Perfectly captures the Ice Prince's cool and endearing aesthetic.",
      price: 3200,
      rating: 4.5,
      image: 'sunghoon doll 02.jpg',
    ),
    const Product(
      id: 'p49',
      name: 'Sunghoon Doll Series 04',
      brand: 'EN-',
      category: 'EN- Plushie',
      description:
          "Versatile Sunghoon plush collection including the rare 'Vampire' and 'Pink' editions. Perfectly captures the Ice Prince's cool and endearing aesthetic.",
      price: 3200,
      rating: 4.5,
      image: 'sunghoon doll 3.jpg',
    ),
    const Product(
      id: 'p50',
      name: 'Sunghoon Doll Series 05',
      brand: 'EN-',
      category: 'EN- Plushie',
      description:
          "Versatile Sunghoon plush collection including the rare 'Vampire' and 'Pink' editions. Perfectly captures the Ice Prince's cool and endearing aesthetic.",
      price: 3200,
      rating: 4.5,
      image: 'sunghoon doll 04.jpg',
    ),
    const Product(
      id: 'p51',
      name: 'Sunghoon Doll Series 06',
      brand: 'EN-',
      category: 'EN- Plushie',
      description:
          "Versatile Sunghoon plush collection including the rare 'Vampire' and 'Pink' editions. Perfectly captures the Ice Prince's cool and endearing aesthetic.",
      price: 3200,
      rating: 4.5,
      image: 'sunghoon doll 05.jpg',
    ),
    const Product(
      id: 'p52',
      name: 'Sunghoon Doll Series 07',
      brand: 'EN-',
      category: 'EN- Plushie',
      description:
          "Versatile Sunghoon plush collection including the rare 'Vampire' and 'Pink' editions. Perfectly captures the Ice Prince's cool and endearing aesthetic.",
      price: 3500,
      rating: 4.5,
      image: 'sunghoon vampire doll.jpg',
    ),
    const Product(
      id: 'p53',
      name: 'Sunoo Doll Series 02',
      brand: 'EN-',
      category: 'EN- Plushie',
      description:
          "The ultimate Sunoo collection. Features the fan-favorite pink hair variant. Vibrant colors and a sunshine aesthetic that mirrors Sunoo's bright personality",
      price: 3500,
      rating: 4.5,
      image: 'sunoo doll 01.jpg',
    ),
    const Product(
      id: 'p54',
      name: 'Sunoo Doll Series 03',
      brand: 'EN-',
      category: 'EN-Plushie',
      description:
          "The ultimate Sunoo collection. Features the fan-favorite pink hair variant. Vibrant colors and a sunshine aesthetic that mirrors Sunoo's bright personality",
      price: 3500,
      rating: 4.5,
      image: 'sunoo doll 02.jpg',
    ),
    const Product(
      id: 'p55',
      name: 'Sunoo Doll Series 04',
      brand: 'EN-',
      category: 'EN- Plushie',
      description:
          "The ultimate Sunoo collection. Features the fan-favorite pink hair variant. Vibrant colors and a sunshine aesthetic that mirrors Sunoo's bright personality",
      price: 3500,
      rating: 4.5,
      image: 'sunoo doll 03.jpg',
    ),
    // TODO: paste your 54 Product entries here exactly from your original file.
  ];

  final Map<String, CartItem> cart = {};
  final List<Review> reviews = [];
  UserProfile user = UserProfile(name: 'ENCORE User', email: 'User@encore.com');

  int selectedIndex = 0;
  String homeCategory = 'All';

  void addToCart(Product product, {int quantity = 1}) {
    setState(() {
      if (cart.containsKey(product.id)) {
        cart[product.id]!.quantity += quantity;
      } else {
        cart[product.id] = CartItem(product: product, quantity: quantity);
      }
    });
  }

  void removeFromCart(String productId) {
    setState(() {
      cart.remove(productId);
    });
  }

  void updateCartQuantity(String productId, int newQty) {
    if (!cart.containsKey(productId)) return;
    setState(() {
      if (newQty <= 0) {
        cart.remove(productId);
      } else {
        cart[productId]!.quantity = newQty;
      }
    });
  }

  void clearCart() {
    setState(() {
      cart.clear();
    });
  }

  void addReview(Review review) {
    setState(() {
      reviews.add(review);
    });
  }

  void updateProfile(UserProfile newUser) {
    setState(() {
      user = newUser;
    });
  }

  void onNavTap(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void setHomeCategory(String category) {
    setState(() {
      homeCategory = category;
      selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (selectedIndex) {
      case 1:
        body = CartScreen(
          cartItems: cart,
          onQuantityChange: updateCartQuantity,
          onRemove: removeFromCart,
          onCheckoutComplete: clearCart,
          themeMode: themeMode,
        );
        break;
      case 2:
        body = ProfileScreen(
          user: user,
          themeMode: themeMode,
          onThemeChanged: toggleTheme,
          onUserChanged: updateProfile,
        );
        break;
      default:
        body = HomeScreen(
          products: allProducts,
          reviews: reviews,
          onAddToCart: addToCart,
          onAddReview: addReview,
          themeMode: themeMode,
          onThemeToggle: toggleTheme,
          initialCategory: homeCategory,
        );
    }

    return Scaffold(
      appBar: widget.isAdmin
          ? AppBar(
              title: const Text('ADMIN CONTROL'),
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            )
          : null,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.pinkAccent],
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'EN‑Core',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Little shop of emotional damage',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.storefront),
              title: const Text('Shop (All)'),
              onTap: () {
                setHomeCategory('All');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('EN‑ series'),
              onTap: () {
                setHomeCategory('EN-');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flash_on),
              title: const Text('JJK chaos'),
              onTap: () {
                setHomeCategory('Keychain');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('ORV feelings'),
              onTap: () {
                setHomeCategory('Plushie');
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Cart'),
              onTap: () {
                onNavTap(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                onNavTap(2);
                Navigator.pop(context);
              },
            ),
            if (widget.isAdmin) const Divider(),
            if (widget.isAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Admin Panel (demo)'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminScreen(products: allProducts),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                // This forces the app to go back to the AuthGate root
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const EncoreRoot()),
                      (route) => false);
                }
              },
            ),
          ],
        ),
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onNavTap,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text(cart.length.toString()),
              isLabelVisible: cart.isNotEmpty,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// ===================== ADMIN SCREEN (SIMPLE DEMO) =====================

class AdminScreen extends StatelessWidget {
  final List<Product> products;

  const AdminScreen({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin – Products'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, i) {
          final p = products[i];
          return Card(
            child: ListTile(
              title: Text(p.name),
              subtitle: Text('Rs ${p.price} · ${p.category}'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('Edit ${p.name}'),
                      content: const Text(
                        'For FYP demo: here admin could edit price, stock, etc.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            // We use Navigator.of(context) directly to ensure we have the right instance
                            Navigator.of(context).pop();
                          },
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ===================== HOME / CATALOG (FROM ORIGINAL) =====================

class HomeScreen extends StatefulWidget {
  final List<Product> products;
  final List<Review> reviews;
  final void Function(Product product, {int quantity}) onAddToCart;
  final void Function(Review review) onAddReview;
  final ThemeMode themeMode;
  final void Function(bool isDark) onThemeToggle;
  final String initialCategory;

  const HomeScreen({
    super.key,
    required this.products,
    required this.reviews,
    required this.onAddToCart,
    required this.onAddReview,
    required this.themeMode,
    required this.onThemeToggle,
    required this.initialCategory,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String search = '';
  late String category;
  final Set<String> favorites = {};
  late AnimationController bannerController;
  late Animation<Offset> bannerSlide;
  late Animation<double> bannerFade;

  @override
  void initState() {
    super.initState();
    category = widget.initialCategory;
    bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    bannerSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: bannerController, curve: Curves.easeOut),
    );
    bannerFade = CurvedAnimation(
      parent: bannerController,
      curve: Curves.easeIn,
    );
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategory != category) {
      setState(() {
        category = widget.initialCategory;
      });
    }
  }

  @override
  void dispose() {
    bannerController.dispose();
    super.dispose();
  }

  List<Product> get _filtered {
    return widget.products.where((p) {
      final matchesCategory = category == 'All'
          ? true
          : p.category.toLowerCase().contains(category.toLowerCase()) ||
              p.brand.toLowerCase().contains(category.toLowerCase());
      final text = search.toLowerCase();
      final matchesSearch = p.name.toLowerCase().contains(text) ||
          p.brand.toLowerCase().contains(text);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void toggleFavorite(String id) {
    setState(() {
      if (favorites.contains(id)) {
        favorites.remove(id);
      } else {
        favorites.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1100
        ? 4
        : width > 800
            ? 3
            : 2;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Builder(
              builder: (ctx) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.menu),
                                onPressed: () => Scaffold.of(ctx).openDrawer(),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ENCORE',
                                style: Theme.of(ctx)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              // Removed the comment markers (//) so the code can actually read this
                              Theme.of(context).brightness == Brightness.dark
                                  ? Icons.wb_sunny_outlined
                                  : Icons.nightlight_round,
                            ),
                            onPressed: () {
                              // This tells the app to flip the current theme
                              widget.onThemeToggle(
                                  Theme.of(context).brightness !=
                                      Brightness.dark);
                            },
                          ),
                        ],
                      ),
                    ),
                    SlideTransition(
                      position: bannerSlide,
                      child: FadeTransition(
                        opacity: bannerFade,
                        child: const _Banner(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: TextField(
                onChanged: (v) => setState(() => search = v),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Looking for something special?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _ChipFilter(
                      label: 'All',
                      icon: Icons.grid_view_rounded,
                      selected: category == 'All',
                      onTap: () => setState(() => category = 'All'),
                    ),
                    _ChipFilter(
                      label: 'EN- Keychain',
                      icon: Icons.favorite,
                      selected: category == 'EN- Keychain',
                      onTap: () => setState(() => category = 'EN- Keychain'),
                    ),
                    _ChipFilter(
                      label: 'EN- Plushies',
                      icon: Icons.vpn_key,
                      selected: category == 'EN- Plushies',
                      onTap: () => setState(() => category = 'EN- Plushies'),
                    ),
                    _ChipFilter(
                      label: 'JJK Keychain',
                      icon: Icons.flash_on,
                      selected: category == 'JJK Keychain',
                      onTap: () => setState(() => category = 'JJK Keychain'),
                    ),
                    _ChipFilter(
                      label: 'Leebit',
                      icon: Icons.pets,
                      selected: category == 'Leebit',
                      onTap: () => setState(() => category = 'Leebit'),
                    ),
                    _ChipFilter(
                      label: 'ORV Plushies',
                      icon: Icons.pets,
                      selected: category == 'ORV',
                      onTap: () => setState(() => category = 'ORV'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final p = _filtered[index];
                  final fav = favorites.contains(p.id);
                  return _AnimatedProductCardWrapper(
                    index: index,
                    child: ProductCard(
                      product: p,
                      isFavorite: fav,
                      onFavoriteToggle: () => toggleFavorite(p.id),
                      onAddToCart: () => widget.onAddToCart(p, quantity: 1),
                      onOpenDetails: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(
                              product: p,
                              onAddToCart: widget.onAddToCart,
                              onAddReview: widget.onAddReview,
                              reviews: widget.reviews
                                  .where((r) => r.productId == p.id)
                                  .toList(),
                            ),
                          ),
                        );
                        setState(() {});
                      },
                    ),
                  );
                },
                childCount: _filtered.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: width < 600 ? 0.65 : 0.78,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: AssetImage('assets/appimages/banner.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.65),
              Colors.black.withOpacity(0.1),
            ],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        padding: const EdgeInsets.all(18),
        alignment: Alignment.bottomLeft,
        child: const Text(
          'Latest merch, for you.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ChipFilter extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ChipFilter({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => onTap(),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _AnimatedProductCardWrapper extends StatelessWidget {
  final int index;
  final Widget child;

  const _AnimatedProductCardWrapper({
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }
}

/// ===================== PRODUCT CARD =====================

class ProductCard extends StatefulWidget {
  final Product product;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onAddToCart;
  final VoidCallback onOpenDetails;

  const ProductCard({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onAddToCart,
    required this.onOpenDetails,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool added = false;

  void handleAdd() {
    widget.onAddToCart();
    setState(() => added = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${widget.product.name} to cart!'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => added = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return GestureDetector(
      onTap: widget.onOpenDetails,
      child: Card(
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'product-image-${p.id}',
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset(
                      'assets/appimages/${p.image}',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      widget.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Colors.pinkAccent,
                    ),
                    onPressed: widget.onFavoriteToggle,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rs ${p.price}',
                        style: const TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: IconButton(
                          key: ValueKey(added),
                          icon: Icon(
                            added ? Icons.check_circle : Icons.add_circle,
                            color: added ? Colors.green : Colors.deepPurple,
                          ),
                          onPressed: handleAdd,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===================== PRODUCT DETAIL =====================

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final void Function(Product product, {int quantity}) onAddToCart;
  final void Function(Review review) onAddReview;
  final List<Review> reviews;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onAddToCart,
    required this.onAddReview,
    required this.reviews,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  int myRating = 0;
  final TextEditingController commentController = TextEditingController();
  bool addedAnimation = false;

  void submitReview() {
    if (myRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give a rating first...')),
      );
      return;
    }
    final comment = commentController.text.trim();
    widget.onAddReview(
      Review(
        productId: widget.product.id,
        userName: 'Encore User',
        comment: comment.isEmpty ? 'No comment' : comment,
        stars: myRating,
      ),
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Review submitted.'),
        content: Text('Your opinion on ${widget.product.name} has been noted!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('OK!'),
          ),
        ],
      ),
    );
    commentController.clear();
    setState(() => myRating = 0);
  }

  void handleAddToCart() {
    widget.onAddToCart(widget.product, quantity: quantity);
    setState(() => addedAnimation = true);
  }

  @override
  Widget build(BuildContext context) {
    final reviews = widget.reviews;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Hero(
              tag: 'product-image-${widget.product.id}',
              child: Container(
                height: 260,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.withOpacity(0.4),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/appimages/${widget.product.image}',
                      fit: BoxFit.cover,
                      height: 220,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rs ${widget.product.price}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.amber,
                            width: 1.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 18,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.product.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Chip(label: Text(widget.product.brand)),
                      const SizedBox(width: 8),
                      Chip(label: Text(widget.product.category)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: const TextStyle(
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Quantity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                        ),
                        onPressed: quantity == 1
                            ? null
                            : () => setState(() => quantity--),
                      ),
                      Text(
                        quantity.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                        ),
                        onPressed: () => setState(() => quantity++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Rate this product',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      final filled = starIndex <= myRating;
                      return IconButton(
                        icon: Icon(
                          filled ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 30,
                        ),
                        onPressed: () => setState(() => myRating = starIndex),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Optional review',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Submit Review',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (reviews.isNotEmpty) ...[
                    const Text(
                      'Recent reviews',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final r in reviews.take(3))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          r.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(r.comment),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            Text(r.stars.toString()),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: SizedBox(
                      key: ValueKey(addedAnimation),
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: Icon(
                          addedAnimation
                              ? Icons.check_circle
                              : Icons.add_shopping_cart_outlined,
                        ),
                        label: Text(
                          addedAnimation ? 'Added to cart' : 'Add to cart',
                        ),
                        onPressed: addedAnimation ? null : handleAddToCart,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  final Map<String, CartItem> cartItems;
  final void Function(String id, int newQty) onQuantityChange;
  final void Function(String id) onRemove;
  final VoidCallback onCheckoutComplete;
  final ThemeMode themeMode;

  const CartScreen({
    super.key,
    required this.cartItems,
    required this.onQuantityChange,
    required this.onRemove,
    required this.onCheckoutComplete,
    required this.themeMode,
  });

  @override
  Widget build(BuildContext context) {
    final items = cartItems.values.toList();
    final total = items.fold<int>(
      0,
      (sum, item) => sum + item.totalPrice,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'Cart is so Empty >_<',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: Image.asset(
                            'assets/appimages/${item.product.image}',
                            width: 50,
                            fit: BoxFit.cover,
                          ),
                          title: Text(item.product.name),
                          subtitle: Text(
                              'Qty: ${item.quantity} · Rs ${item.totalPrice}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            onPressed: () => onRemove(item.product.id),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10)
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount:',
                              style: TextStyle(fontSize: 16)),
                          Text(
                            'Rs $total',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 55),
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () {
                          // THE PROFESSIONAL DIALOG
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Confirm Order"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                      "Are you sure you want to place this order?"),
                                  const Divider(height: 30),
                                  Text("Items: ${items.length}"),
                                  Text("Total: Rs $total",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Close dialog
                                    onCheckoutComplete(); // Clear the cart

                                    // Generate a professional looking Order ID
                                    String professionalId =
                                        'EN-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => OrderConfirmationScreen(
                                          orderId: professionalId,
                                          totalAmount: total,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text("Place Order"),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text(
                          'PROCEED TO CHECKOUT',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// ===================== ORDER CONFIRMATION =====================

class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;
  final int totalAmount;

  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            const Text('Order has been Placed!(RIP your savings)'),
            Text('Order ID: $orderId'),
            Text('Total: Rs $totalAmount'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
// ===================== PROFILE / SETTINGS =====================

class ProfileScreen extends StatefulWidget {
  final UserProfile user;
  final ThemeMode themeMode;
  final void Function(bool isDark) onThemeChanged;
  final void Function(UserProfile newUser) onUserChanged;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.themeMode,
    required this.onThemeChanged,
    required this.onUserChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController nameCtrl;
  late TextEditingController emailCtrl;
  bool showAnime = true;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.user.name);
    emailCtrl = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    super.dispose();
  }

  void saveProfile() {
    widget.onUserChanged(
      UserProfile(
        name:
            nameCtrl.text.trim().isEmpty ? 'ENCORE User' : nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile Updated!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // THIS IS THE FIX: We check the REAL app theme every time the screen draws
    bool isCurrentlyDark = widget.themeMode == ThemeMode.dark;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.deepPurple,
                child: Text(
                  nameCtrl.text.isEmpty ? 'E' : nameCtrl.text[0].toUpperCase(),
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EN‑Core Profile',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Text('Shopping Spree Mode : ON',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
                labelText: 'Display name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailCtrl,
            decoration: const InputDecoration(
                labelText: 'Email', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: saveProfile,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent.withOpacity(0.1)),
              child: const Text('Save profile'),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          const Text('App settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          // FIXED THEME SWITCH
          SwitchListTile(
            title: const Text('Dark theme'),
            value: isCurrentlyDark, // Always matches the actual app state
            onChanged: (v) {
              widget.onThemeChanged(v); // Tell the root app to change
            },
            secondary: const Icon(Icons.brightness_6_outlined),
          ),

          SwitchListTile(
            title: const Text('Show anime section'),
            value: showAnime,
            onChanged: (v) => setState(() => showAnime = v),
            secondary: const Icon(Icons.movie_outlined),
          ),

          const Divider(),

          // ADDED LOGOUT BUTTON HERE FOR CONVENIENCE
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),

          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About ENCore'),
            subtitle: Text('A fun project made with love for merch lovers.'),
          ),
        ],
      ),
    );
  }
}
