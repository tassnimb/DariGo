import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> register() async {

    bool success = await ApiService.register(
      username: usernameController.text,
      email: emailController.text,
      phone: phoneController.text,
      password: passwordController.text,
    );

    if(success){

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Compte créé avec succès"),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );

    }else{

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur d'inscription"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [

              const Text(
                "DariGo",
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: "Phone",
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                ),
              ),

              const SizedBox(height: 25),

              ElevatedButton(
                onPressed: register,
                child: const Text("Sign Up"),
              ),

              TextButton(
                onPressed: (){
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text("Already have an account ? Sign In"),
              )
            ],
          ),
        ),
      ),
    );
  }
}