#!/bin/bash

# Navigate to the project root (ensure you run this from the 'skindare' root folder)
# Create main directories
mkdir -p lib/core/services
mkdir -p lib/core/constants
mkdir -p lib/core/utils
mkdir -p lib/shared
mkdir -p lib/features

# Define the list of features
features=("auth" "routine" "skincare" "skin_log" "history" "profile")

# Loop through and create subfolders for each feature
for feature in "${features[@]}"
do
    mkdir -p "lib/features/$feature/screens"
    mkdir -p "lib/features/$feature/models"
    mkdir -p "lib/features/$feature/data"
    mkdir -p "lib/features/$feature/widgets"
done

# Create placeholder Dart files for core
touch lib/core/services/firebase_service.dart
touch lib/core/constants/route_names.dart

# Create placeholder Dart files for screens
touch lib/features/auth/screens/login_screen.dart
touch lib/features/routine/screens/home_screen.dart
touch lib/features/skincare/screens/product_list_screen.dart
touch lib/features/skincare/screens/product_detail_screen.dart
touch lib/features/skincare/screens/add_edit_product_screen.dart
touch lib/features/skin_log/screens/add_log_screen.dart
touch lib/features/history/screens/history_screen.dart
touch lib/features/profile/screens/profile_screen.dart

echo "Skindare folder structure created successfully!"