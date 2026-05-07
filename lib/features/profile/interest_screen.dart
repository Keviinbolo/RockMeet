import 'package:flutter/material.dart';
import 'package:myapp/core/services/profile_service.dart';

class InterestScreen extends StatefulWidget {
  // AÑADIDO: Recibir la lista de intereses desde el perfil para poder editarla
  final List<Interest> currentInterests;
  const InterestScreen({super.key, required this.currentInterests});

  @override
  State<InterestScreen> createState() => _InterestScreenState();
}

class Interest {
  final IconData icon;
  final String label;
  bool selected;
  final List<String> subInterests;
  Set<String> selectedSubInterests;

  Interest(
    this.icon,
    this.label, {
    this.selected = false,
    this.subInterests = const [],
    Set<String>? selectedSubInterests,
  }) : selectedSubInterests = selectedSubInterests ?? {};
}

class _InterestScreenState extends State<InterestScreen> {
  // Usamos la lista que nos pasan desde fuera
  late List<Interest> _interests;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _interests = widget.currentInterests
        .map(
          (interest) => Interest(
            interest.icon,
            interest.label,
            selected: interest.selected,
            subInterests: List<String>.from(interest.subInterests),
            selectedSubInterests: Set<String>.from(
              interest.selectedSubInterests,
            ),
          ),
        )
        .toList();
  }

  Future<void> _saveInterests() async {
    if (_isSaving) return;

    final selectedInterests = _interests
        .where((interest) => interest.selected)
        .map((interest) => interest.label)
        .toList();

    final interestsWithSubInterests = <String, List<String>>{};
    for (final interest in _interests) {
      if (interest.selected && interest.selectedSubInterests.isNotEmpty) {
        interestsWithSubInterests[interest.label] =
            interest.selectedSubInterests.toList();
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ProfileService.instance.updateCurrentUserProfile(
        interests: selectedInterests,
        interestsWithSubInterests: interestsWithSubInterests,
      );

      if (!mounted) return;
      Navigator.pop(context, _interests);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron guardar los intereses: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // --- FUNCIÓN QUE MUESTRA EL MENÚ DESPLEGABLE TIPO IMAGEN ---
  void _showSubInterestsModal(BuildContext context, Interest interest) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Para que se vean los bordes curvos
      isScrollControlled: true,
      builder: (BuildContext context) {
        // StatefulBuilder permite que el modal se actualice al tocar los botones por dentro
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF141419), // Fondo oscuro de tu imagen
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.only(
                  left: 20, right: 20, top: 12, bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barrita superior (Handle)
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Cabecera: Título (Ej. Música) y Botón "Hecho"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        interest.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Cierra el modal
                          // Opcional: Marcar la categoría principal como seleccionada 
                          // si el usuario ha elegido al menos un sub-interés
                          setState(() {
                            interest.selected =
                                interest.selectedSubInterests.isNotEmpty;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C2C30),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          'Hecho',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Chips (Rock, Techno, etc.)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: interest.subInterests.map((sub) {
                      final isSelected =
                          interest.selectedSubInterests.contains(sub);
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            if (isSelected) {
                              interest.selectedSubInterests.remove(sub);
                            } else {
                              interest.selectedSubInterests.add(sub);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.15)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : Colors.grey.shade600,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            sub,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade400,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  // --------------------------------------------------------------

  Widget _buildInterestRow(Interest interest) {
    return InkWell(
      // Al hacer clic, ahora abrimos el modal
      onTap: () {
        _showSubInterestsModal(context, interest);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(
                  0.08,
                ), // Fondo morado muy claro
                shape: BoxShape.circle,
              ),
              child: Icon(
                interest.icon,
                color: Colors.deepPurple.shade400,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                interest.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              interest.selected ? 'Seleccionado' : 'Seleccionar',
              style: TextStyle(
                color: interest.selected
                    ? Colors.deepPurple
                    : Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // WillPopScope (o PopScope en versiones muy nuevas) sirve para interceptar cuando el usuario vuelve atrás
    return PopScope(
      canPop: false, // Controlamos manualmente la vuelta atrás
      onPopInvoked: (didPop) {
        if (didPop) return;
        // Al volver atrás, devolvemos la lista actualizada
        Navigator.pop(context, _interests);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Intereses'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _interests),
          ),
          actions: [
            TextButton.icon(
              onPressed: _isSaving ? null : _saveInterests,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Guardar'),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: _interests.length,
            itemBuilder: (context, index) => _buildInterestRow(_interests[index]),
          ),
        ),
      ),
    );
  }
}