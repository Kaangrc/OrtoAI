import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    //Kaç saniye bekleyeceğini belirtiyoruz
    Future.delayed(const Duration(seconds: 4), () {
      //Burada yönlendirme işlemini yapıyoruz
      Navigator.pushReplacementNamed(context, '/promotion');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //Burada bir resim ekliyoruz
            Image.asset('assets/images/Computer.png'),
            //Burada bir yazı ekliyoruz
            const Text(
              'Welcome to MyApp',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator()
          ],
        ),
      ),
    );
  }
}
