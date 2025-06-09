// lib/services/storage_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _bucketName = 'recipeimages'; // Nama bucket yang kita buat

  /// Mengunggah file ke Supabase Storage dan mengembalikan URL download-nya.
  ///
  /// [file]: File yang akan diunggah.
  /// [path]: Path tujuan di Supabase Storage (contoh: 'user_id/file_name.jpg').
  Future<String> uploadFile(File file, String path) async {
    try {
      // Mengunggah file
      await _supabase.storage.from(_bucketName).upload(
            path,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600', // Cache selama 1 jam
              upsert: false, // Jangan timpa jika file sudah ada
            ),
          );

      // Mendapatkan URL publik dari file yang diunggah
      final String publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(path);

      return publicUrl;
    } on StorageException catch (e) {
      debugPrint('Error uploading file to Supabase: ${e.message}');
      throw Exception('Gagal mengunggah file: ${e.message}');
    } catch (e) {
      debugPrint('An unexpected error occurred: $e');
      throw Exception('Terjadi kesalahan tidak terduga saat mengunggah.');
    }
  }

  /// Menghapus file dari Supabase Storage berdasarkan URL-nya.
  Future<void> deleteFile(String fileUrl) async {
    if (fileUrl.isEmpty) return;

    // Ekstrak path file dari URL lengkap
    // Contoh URL: https://<project-ref>.supabase.co/storage/v1/object/public/recipe_images/user_id/file_name.jpg
    // Kita hanya butuh: user_id/file_name.jpg
    final path = _extractPathFromUrl(fileUrl);
    if (path == null) {
      debugPrint('Could not extract path from URL: $fileUrl');
      return;
    }
    
    try {
      await _supabase.storage.from(_bucketName).remove([path]);
      debugPrint('File deleted successfully from Supabase: $path');
    } on StorageException catch (e) {
      debugPrint('Error deleting file from Supabase: ${e.message}');
      // Anda bisa memilih untuk melempar exception lagi atau tidak
    } catch (e) {
      debugPrint('An unexpected error occurred during Supabase deletion: $e');
    }
  }
  
  // Helper untuk mengekstrak path dari URL Supabase
  String? _extractPathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      // Path dimulai setelah nama bucket, jadi kita cari index 'recipe_images'
      final bucketIndex = segments.indexOf(_bucketName);
      if (bucketIndex != -1 && segments.length > bucketIndex + 1) {
        return segments.sublist(bucketIndex + 1).join('/');
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}