import 'package:flutter/material.dart';
import '../../services/voice_search_service.dart';

class VoiceSearchScreen extends StatefulWidget {
  const VoiceSearchScreen({super.key});

  @override
  State<VoiceSearchScreen> createState() => _VoiceSearchScreenState();
}

class _VoiceSearchScreenState extends State<VoiceSearchScreen> {
  bool _isListening = false;
  String _recognizedText = '';
  final List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _initializeVoiceSearch();
  }

  Future<void> _initializeVoiceSearch() async {
    await VoiceSearchService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Search'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildVoiceInput(),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceInput() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _toggleListening,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                size: 48,
                color: _isListening ? Colors.red : Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isListening ? 'Listening...' : 'Tap to speak',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_recognizedText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _recognizedText,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Say something to search',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try saying "Pizza" or "Burger"',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildResultCard(_searchResults[index]);
      },
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    final type = result['type'];
    final name = result['name'];
    final image = result['image'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        type == 'restaurant' ? Icons.restaurant : Icons.restaurant_menu,
                        size: 30,
                      );
                    },
                  ),
                )
              : Icon(
                  type == 'restaurant' ? Icons.restaurant : Icons.restaurant_menu,
                  size: 30,
                ),
        ),
        title: Text(name),
        subtitle: Text(type == 'restaurant' ? 'Restaurant' : 'Menu Item'),
        trailing: Icon(
          type == 'restaurant' ? Icons.store : Icons.fastfood,
          color: Colors.grey,
        ),
      ),
    );
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await VoiceSearchService.stopListening();
      setState(() {
        _isListening = false;
      });
    } else {
      final success = await VoiceSearchService.startListening(
        onResult: (text) {
          setState(() {
            _recognizedText = text;
          });
        },
        onError: (error) {
          setState(() {
            _recognizedText = error;
          });
        },
      );

      if (success) {
        setState(() {
          _isListening = true;
          _recognizedText = '';
        });
      }
    }
  }

  Future<void> _performSearch(String query) async {
    final results = await VoiceSearchService.searchByVoice(query);
    setState(() {
      _searchResults = results;
    });
  }
}
