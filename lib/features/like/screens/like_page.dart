import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    home: LikesPage(), 
    debugShowCheckedModeBanner: false,
  ));
}

// 1. Definición del Modelo de Datos
class LikePerson {
  final int id;
  final String name;
  final int age;
  final String image;

  LikePerson({
    required this.id,
    required this.name,
    required this.age,
    required this.image,
  });
}

// 2. La Página Principal
class LikesPage extends StatelessWidget {
  const LikesPage({super.key});

  // Datos de ejemplo (puedes mover esto a un servicio o estado)
  List<LikePerson> get _data => [
    LikePerson(id: 1, name: "Sofía", age: 28, image: "https://images.unsplash.com/photo-1690444963408-9573a17a8058?w=500"),
    LikePerson(id: 2, name: "Carlos", age: 32, image: "https://images.unsplash.com/photo-1695485121912-25c7ea05119c?w=500"),
    LikePerson(id: 3, name: "María", age: 26, image: "https://images.unsplash.com/photo-1522206038088-8698bcefa6a0?w=500"),
    LikePerson(id: 4, name: "Diego", age: 30, image: "https://images.unsplash.com/photo-1616235931343-10a92ecaeaf2?w=500"),
    LikePerson(id: 5, name: "Valentina", age: 27, image: "https://images.unsplash.com/photo-1660152988640-99bcdecf2bc5?w=500"),
    LikePerson(id: 6, name: "Alejandro", age: 29, image: "https://images.unsplash.com/photo-1622626426572-c268eb006092?w=500"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B), // zinc-950
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              const Text(
                "Personas que te dieron like",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${_data.length} personas están interesadas en ti",
                style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 16),
              ),
              const SizedBox(height: 32),

              // --- Grid de Likes ---
              GridView.builder(
                shrinkWrap: true, // Importante para que funcione dentro de SingleChildScrollView
                physics: const NeverScrollableScrollPhysics(), // El scroll lo maneja el SingleChildScrollView
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3 / 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _data.length,
                itemBuilder: (context, index) => _buildLikeCard(_data[index]),
              ),

              const SizedBox(height: 32),


            ],
          ),
        ),
      ),
    );
  }

  // Widget para cada tarjeta individual
  Widget _buildLikeCard(LikePerson person) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF18181B), // zinc-900
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen con Blur
          Image.network(person.image, fit: BoxFit.cover),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),
          ),

          // Gradiente inferior para legibilidad del texto
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0xCC09090B),
                  Color(0xFF09090B),
                ],
              ),
            ),
          ),

          // Icono de Candado
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                color: Colors.white70,
                size: 28,
              ),
            ),
          ),

          // Información del perfil
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${person.name}, ${person.age}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  "Dale like para ver perfil",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget del Banner de pago
  
}