import 'package:flutter/material.dart';

class CustomAboutDialog extends StatelessWidget {
  const CustomAboutDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          width: 281,
          height: 223,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                offset: const Offset(0, 4),
                blurRadius: 4,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Header Text "MADE WITH BY"
              Positioned(
                left: 75,
                top: 21,
                child: Row(
                  children: [
                    Text(
                      'MADE WITH',
                      style: TextStyle(
                        fontFamily: 'Alexandria',
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        letterSpacing: 2, // 0.52em approx
                        color: const Color(0xFF888383),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.favorite,
                      size: 14,
                      color: Color(0xFF8A38F5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'BY',
                      style: TextStyle(
                        fontFamily: 'Alexandria',
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        letterSpacing: 2,
                        color: const Color(0xFF888383),
                      ),
                    ),
                  ],
                ),
              ),

              // Shopnil
              _buildTeamMember(
                top: 58,
                name: 'SHOPNIL KARMAKAR',
                imageTop: 56,
                imageLeft: 32,
                color: Colors.blue.shade100, // Placeholder color
                imageAsset: 'assets/images/1.jpg',
              ),

              // Sabrina
              _buildTeamMember(
                top: 100,
                name: 'SABRINA TASNIM IMU',
                imageTop: 97,
                imageLeft: 33,
                color: Colors.pink.shade100, // Placeholder color
                imageAsset: 'assets/images/2.jpg',
              ),

              // Muzahidul
              _buildTeamMember(
                top: 139,
                name: 'MUZAHIDUL ISLAM JOY',
                imageTop: 137,
                imageLeft: 33,
                color: Colors.green.shade100, // Placeholder color
                isFlipped: true, // CSS had transform: matrix(-1, 0, 0, 1, 0, 0)
                imageAsset: 'assets/images/3.jpg',
              ),

              // Arpita
              _buildTeamMember(
                top: 178,
                name: 'ARPITA BISWAS',
                imageTop: 175,
                imageLeft: 33,
                color: Colors.orange.shade100, // Placeholder color
                imageAsset: 'assets/images/4.jpg',
              ),

              // // Heart Icon Top Right
              // Positioned(
              //   left: 188,
              //   top: 16,
              //   child: Icon(
              //     Icons.favorite,
              //     color: const Color(0xFF8A38F5),
              //     size: 24,
              //   ),
              // ),

              // Close Button
              Positioned(
                right: 10,
                top: 10,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.withOpacity(0.1),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamMember({
    required double top,
    required String name,
    required double imageTop,
    required double imageLeft,
    required Color color,
    required String imageAsset,
    bool isFlipped = false,
  }) {
    return Stack(
      children: [
        // Name Box
        Positioned(
          left: 70,
          top: top,
          child: Container(
            width: 178, // Adjusted to match smallest width in CSS or consistent
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              name,
              style: const TextStyle(
                fontFamily: 'Alexandria',
                fontWeight: FontWeight.w300,
                fontSize: 11,
                color: Color(0xFF565656),
              ),
            ),
          ),
        ),
        // Image Circle
        Positioned(
          left: imageLeft,
          top: imageTop,
          child: Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage(imageAsset),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
