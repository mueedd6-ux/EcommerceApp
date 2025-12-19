import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
  }
  runApp(const MueedECommerceApp());
}

class MueedECommerceApp extends StatelessWidget {
  const MueedECommerceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Mueed E-Commerce",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFd4af37),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFd4af37),
          elevation: 0,
          titleTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFd4af37),
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

// --- AUTH WRAPPER ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.amber)));
        }
        if (snapshot.hasData && snapshot.data != null) {
          if (snapshot.data!.email == "admin@mueed.com") {
            return const AdminPanel();
          }
          return const MainNavigation();
        }
        return const RegistrationScreen();
      },
    );
  }
}

// --- REGISTRATION SCREEN ---
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_email.text.isEmpty || _password.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
          email: _email.text.trim(), password: _password.text.trim());

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCred.user!.uid)
          .set({'email': _email.text.trim(), 'isAdmin': false});

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mueed Luxury Store")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.shopping_bag_outlined, size: 80, color: Color(0xFFd4af37)),
          const SizedBox(height: 20),
          TextField(controller: _email, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder())),
          const SizedBox(height: 25),
          _isLoading
              ? const CircularProgressIndicator(color: Colors.amber)
              : ElevatedButton(onPressed: _signUp, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text("LOGIN / REGISTER")),
        ]),
      ),
    );
  }
}

// --- NAVIGATION ---
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final List<Widget> _screens = [const HomeScreen(), const ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFFd4af37),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Shop"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }
}

// --- HOME SCREEN ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _search = "";
  String _category = "All";
  final List<String> _cats = ["All", "Phones", "Shoes", "Watches"];

  // Aapki Images folder ke mutabiq updated list
  final List<Map<String, dynamic>> _staticProducts = [
    {"name": "Phone Elite", "price": 45000, "category": "Phones", "image": "assets/images/phone.jpg"},
    {"name": "Pro Phone", "price": 85000, "category": "Phones", "image": "assets/images/phone2.jpg"},
    {"name": "Sports Shoes", "price": 7500, "category": "Shoes", "image": "assets/images/shoes.jpg"},
    {"name": "Sneakers X", "price": 9200, "category": "Shoes", "image": "assets/images/shoes2.jpg"},
    {"name": "Watch Classic", "price": 12500, "category": "Watches", "image": "assets/images/watch.jpg"},
    {"name": "Smart Watch", "price": 15000, "category": "Watches", "image": "assets/images/watch3.jpg"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MUEED LUXURY"),
        actions: [IconButton(icon: const Icon(Icons.shopping_cart_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())))],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Search luxury items...",
              prefixIcon: const Icon(Icons.search, color: Color(0xFFd4af37)),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: _cats.map((c) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(c),
                  selected: _category == c,
                  onSelected: (v) => setState(() => _category = c),
                  selectedColor: const Color(0xFFd4af37),
                  labelStyle: TextStyle(color: _category == c ? Colors.black : Colors.white),
                ),
              )).toList()),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (context, snapshot) {
              var docs = (snapshot.hasData && snapshot.data!.docs.isNotEmpty)
                  ? snapshot.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList()
                  : _staticProducts;

              var filtered = docs.where((p) {
                return (_category == "All" || p['category'] == _category) &&
                    p['name'].toString().toLowerCase().contains(_search.toLowerCase());
              }).toList();

              return GridView.builder(
                padding: const EdgeInsets.all(15),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 0.75),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final p = filtered[i];
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(p))),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(20)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: Image.asset(p['image'], fit: BoxFit.cover, width: double.infinity,
                              errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.image_not_supported)),
                            ),
                          ),
                        ),
                        Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1),
                              const SizedBox(height: 5),
                              Text("Rs. ${p['price']}", style: const TextStyle(color: Color(0xFFd4af37), fontSize: 14)),
                            ])),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        )
      ]),
    );
  }
}

// --- PRODUCT DETAILS ---
class ProductDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const ProductDetailsScreen(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(data['name'])),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: 350,
          width: double.infinity,
          child: Image.asset(data['image'], fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 100),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(data['name'], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              Text("Rs. ${data['price']}", style: const TextStyle(fontSize: 22, color: Color(0xFFd4af37), fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 15),
            const Text("Premium quality product with luxury finish. Handcrafted for the best experience.", style: TextStyle(color: Colors.grey, fontSize: 16)),
          ]),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('cart').doc(data['name']).set(data);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to Luxury Cart!")));
                }
              },
              child: const Text("ADD TO CART", style: TextStyle(fontSize: 18))),
        ),
      ]),
    );
  }
}

// --- CART SCREEN ---
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Please Login")));

    return Scaffold(
      appBar: AppBar(title: const Text("My Cart")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('cart').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var cartItems = snapshot.data!.docs;
          double total = 0;
          for (var item in cartItems) { total += (item['price'] ?? 0); }

          if (cartItems.isEmpty) return const Center(child: Text("Your cart is empty."));

          return Column(children: [
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, i) {
                  var item = cartItems[i].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: ClipRRect(borderRadius: BorderRadius.circular(5), child: Image.asset(item['image'], width: 50, height: 50, fit: BoxFit.cover)),
                    title: Text(item['name']),
                    subtitle: Text("Rs. ${item['price']}", style: const TextStyle(color: Color(0xFFd4af37))),
                    trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => cartItems[i].reference.delete()),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text("Subtotal:", style: TextStyle(fontSize: 18)),
                  Text("Rs. $total", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFd4af37))),
                ]),
                const SizedBox(height: 15),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutScreen(total: total))),
                    child: const Text("PROCEED TO CHECKOUT")
                )
              ]),
            )
          ]);
        },
      ),
    );
  }
}

// --- CHECKOUT SCREEN ---
class CheckoutScreen extends StatefulWidget {
  final double total;
  const CheckoutScreen({super.key, required this.total});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  Future<void> _placeOrder() async {
    if (_name.text.isEmpty || _address.text.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('orders').add({
      'uid': user.uid,
      'customerName': _name.text,
      'phone': _phone.text,
      'address': _address.text,
      'total': widget.total,
      'status': 'Pending',
      'date': FieldValue.serverTimestamp(),
    });

    var cart = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('cart').get();
    for (var d in cart.docs) { await d.reference.delete(); }

    if (mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Placed Successfully!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _phone, decoration: const InputDecoration(labelText: "Phone Number", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _address, maxLines: 3, decoration: const InputDecoration(labelText: "Delivery Address", border: OutlineInputBorder())),
          const Spacer(),
          Text("Total Payable: Rs. ${widget.total}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _placeOrder, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text("PLACE ORDER (COD)")),
        ]),
      ),
    );
  }
}

// --- PROFILE SCREEN ---
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text("My Account")),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const CircleAvatar(radius: 50, backgroundColor: Color(0xFFd4af37), child: Icon(Icons.person, size: 50, color: Colors.black)),
          const SizedBox(height: 15),
          Text(user?.email ?? "Guest User", style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 30),
          ElevatedButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text("LOGOUT")),
        ]),
      ),
    );
  }
}

// --- ADMIN PANEL ---
class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Orders"), actions: [IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout))]),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').orderBy('date', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No orders yet."));

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, i) {
              var o = snapshot.data!.docs[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                color: Colors.grey[900],
                child: ListTile(
                  title: Text(o['customerName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${o['address']} \nRs.${o['total']}"),
                  trailing: const Chip(label: Text("Pending"), backgroundColor: Colors.amber),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}