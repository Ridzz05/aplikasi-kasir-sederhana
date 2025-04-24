import 'package:flutter/material.dart';

class PageControllerProvider extends ChangeNotifier {
  final PageController _pageController = PageController();
  
  PageController get pageController => _pageController;
  
  int _currentIndex = 0;
  
  int get currentIndex => _currentIndex;
  
  void jumpToPage(int index) {
    _pageController.jumpToPage(index);
    _currentIndex = index;
    notifyListeners();
  }
  
  void setPage(int index) {
    _currentIndex = index;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
} 