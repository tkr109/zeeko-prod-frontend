import 'package:flutter/material.dart';
import 'dart:convert'; // For base64 decoding

class EventCard extends StatelessWidget {
  final String id;
  final String title;
  final String date;
  final String location;
  final String? image; // Base64 string, if available
  final String? imageUrl; // URL, if available
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    this.image,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Debugging: Print the image URL or Base64
    print('Image for Event: $title');
    if (image != null) {
      print(
          'Base64 Image: ${image!.substring(0, 30)}...'); // Print first 30 chars for readability
    } else {
      print('Image URL: $imageUrl');
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        color: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              SizedBox(
                width: 90,
                height: 90,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: image != null
                      ? Image.memory(
                          base64Decode(image!), // Decode base64 image
                          fit: BoxFit.cover, // Cover the space
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderImage(),
                        )
                      : Image.network(
                          imageUrl ?? 'https://via.placeholder.com/150',
                          fit: BoxFit.cover, // Cover the space
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderImage(),
                        ),
                ),
              ),
              const SizedBox(width: 15),
              // Details section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 5),
                        Text(
                          date,
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[700],
      child: const Center(
        child: Icon(Icons.image_not_supported, color: Colors.white, size: 40),
      ),
    );
  }
}
