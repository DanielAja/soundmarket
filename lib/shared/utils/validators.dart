/// Input validation functions
class Validators {
  // Email validation
  static bool isValidEmail(String email) {
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegExp.hasMatch(email);
  }
  
  // Email validation with error message
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!isValidEmail(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }
  
  // Password validation
  static bool isValidPassword(String password) {
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
    final passwordRegExp = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d\w\W]{8,}$',
    );
    return passwordRegExp.hasMatch(password);
  }
  
  // Password validation with error message
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }
  
  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }
  
  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }
  
  // Number validation
  static String? validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }
  
  // Positive number validation
  static String? validatePositiveNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (number <= 0) {
      return 'Please enter a positive number';
    }
    return null;
  }
  
  // Integer validation
  static String? validateInteger(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (int.tryParse(value) == null) {
      return 'Please enter a valid integer';
    }
    return null;
  }
  
  // Positive integer validation
  static String? validatePositiveInteger(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    final number = int.tryParse(value);
    if (number == null) {
      return 'Please enter a valid integer';
    }
    if (number <= 0) {
      return 'Please enter a positive integer';
    }
    return null;
  }
  
  // URL validation
  static bool isValidUrl(String url) {
    final urlRegExp = RegExp(
      r'^(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    return urlRegExp.hasMatch(url);
  }
  
  // URL validation with error message
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }
    if (!isValidUrl(value)) {
      return 'Please enter a valid URL';
    }
    return null;
  }
  
  // Phone number validation
  static bool isValidPhone(String phone) {
    final phoneRegExp = RegExp(
      r'^\+?[0-9]{10,15}$',
    );
    return phoneRegExp.hasMatch(phone);
  }
  
  // Phone validation with error message
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!isValidPhone(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }
  
  // Date validation
  static bool isValidDate(String date) {
    try {
      final dateTime = DateTime.parse(date);
      return dateTime.isAfter(DateTime(1900)) && 
             dateTime.isBefore(DateTime(2100));
    } catch (e) {
      return false;
    }
  }
  
  // Date validation with error message
  static String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }
    if (!isValidDate(value)) {
      return 'Please enter a valid date';
    }
    return null;
  }
  
  // Credit card validation
  static bool isValidCreditCard(String cardNumber) {
    // Remove spaces and dashes
    cardNumber = cardNumber.replaceAll(RegExp(r'[\s-]'), '');
    
    if (!RegExp(r'^[0-9]{13,19}$').hasMatch(cardNumber)) {
      return false;
    }
    
    // Luhn algorithm
    int sum = 0;
    bool alternate = false;
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int n = int.parse(cardNumber[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }
      sum += n;
      alternate = !alternate;
    }
    
    return (sum % 10 == 0);
  }
  
  // Credit card validation with error message
  static String? validateCreditCard(String? value) {
    if (value == null || value.isEmpty) {
      return 'Credit card number is required';
    }
    if (!isValidCreditCard(value)) {
      return 'Please enter a valid credit card number';
    }
    return null;
  }
}
