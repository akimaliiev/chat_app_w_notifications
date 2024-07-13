import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message, 
              size: 70,
              color: Theme.of(context).colorScheme.primary,
            ),

            const SizedBox(height: 50,),

            Text(
              "Добро пожаловать обратно! Мы скучали",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 25,),
          ],
        ),
      ),
    );
  }
}