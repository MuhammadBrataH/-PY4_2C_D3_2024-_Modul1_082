import 'package:flutter/material.dart';
import 'package:logbook_app_082/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int step = 1;
  final List<Map<String, String>> onboardingData = [
    {
      "image": "assets/images/onboarding1.jpeg",
      "title": "Selamat Datang di Logbook App",
      "description":
          "Aplikasi untuk mencatat aktivitas harian Anda dengan mudah.",
    },
    {
      "image": "assets/images/onboarding2.jpeg",
      "title": "Fitur Utama",
      "description":
          "Catat aktivitas, lihat riwayat, dan kelola catatan Anda dengan fitur yang lengkap.",
    },
    {
      "image": "assets/images/onboarding3.jpeg",
      "title": "Mulai Sekarang!",
      "description":
          "Buat akun dan mulai mencatat aktivitas harian Anda sekarang juga!",
    },
  ];
  @override
  Widget build(BuildContext context) {
    final data = onboardingData[step - 1];
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gambar onboarding
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  data["image"]!,
                  height: 280,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 30),

              // Judul
              Text(
                data["title"]!,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Deskripsi
              Text(
                data["description"]!,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Page Indicator (titik-titik)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: step == index + 1 ? 14 : 10,
                    height: step == index + 1 ? 14 : 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: step == index + 1
                          ? Colors.blue
                          : Colors.grey.shade300,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),

              // Tombol Next / Mulai
              ElevatedButton(
                onPressed: () {
                  if (step >= 3) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginView(),
                      ),
                    );
                  } else {
                    setState(() {
                      step++;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                ),
                child: Text(step >= 3 ? "Mulai" : "Next"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
