# TODO: Fix Auth Screen Layout for Small Devices

## Task
Make the "OR" divider and "Continue with Google" button visible on small devices without scrolling, while maintaining space for validation errors.

## Steps:
1. [x] Read and analyze auth_screen.dart
2. [x] Read and analyze app_text_field.dart to understand validation behavior
3. [ ] Modify auth_screen.dart to use dynamic PageView height
   - Use MediaQuery to calculate available screen height
   - Make PageView height responsive based on device size
   - Ensure OR divider and Google button are always visible
4. [ ] Test the changes

## Solution Approach:
- Calculate dynamic height for PageView using MediaQuery.of(context).size.height
- Use a flexible height that adapts to both small and large screens
- Ensure minimum space for validation errors while preventing overflow on small devices
