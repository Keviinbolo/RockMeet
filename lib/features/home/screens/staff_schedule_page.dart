import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:RockMeet/core/services/schedule_service.dart';

class StaffSchedulePage extends StatefulWidget {
  const StaffSchedulePage({super.key});

  @override
  State<StaffSchedulePage> createState() => _StaffSchedulePageState();
}

class _StaffSchedulePageState extends State<StaffSchedulePage> {
  final _picker = ImagePicker();
  final Map<String, bool> _uploading = {};

  Future<void> _pickAndUpload(String className) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploading[className] = true);
    try {
      final bytes = await picked.readAsBytes();
      await ScheduleService.instance.uploadScheduleImage(className, bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Horario de $className actualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading[className] = false);
    }
  }

  Future<void> _remove(String className) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar horario'),
        content: Text('¿Eliminar el horario de $className?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ScheduleService.instance.removeScheduleImage(className);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Horario de $className eliminado')),
      );
    }
  }

  void _previewImage(String imageUrl, String className) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text('Horario — $className'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: InteractiveViewer(
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (ctx, e, st) =>
                    const Center(child: Icon(Icons.broken_image, size: 64)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Horarios de Clase')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ScheduleService.availableClasses.length,
        itemBuilder: (context, index) {
          final className = ScheduleService.availableClasses[index];
          return StreamBuilder<String?>(
            stream: ScheduleService.instance.watchScheduleImageUrl(className),
            builder: (context, snapshot) {
              final imageUrl = snapshot.data;
              final isUploading = _uploading[className] ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: GestureDetector(
                    onTap: imageUrl != null
                        ? () => _previewImage(imageUrl, className)
                        : null,
                    child: imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, e, st) => const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  title: Text(
                    className,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    imageUrl != null ? 'Horario asignado' : 'Sin horario',
                    style: TextStyle(
                      color: imageUrl != null ? Colors.green : Colors.grey,
                    ),
                  ),
                  trailing: isUploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.upload),
                              tooltip: 'Subir horario',
                              onPressed: () => _pickAndUpload(className),
                            ),
                            if (imageUrl != null)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: 'Eliminar horario',
                                onPressed: () => _remove(className),
                              ),
                          ],
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
