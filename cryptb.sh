#!/bin/bash

# Define an array of supported package managers
package_managers=("apt" "dnf" "yum" "pacman" "zypper")

# Function to detect the package manager
pm_detect() {
  # Loop through the package managers array
  for pm in "${package_managers[@]}"; do
    # Check if the package manager is available on the system
    if command -v "$pm" >/dev/null 2>&1; then
      echo "$pm"
      return
    fi
  done
}

# Function to check if GPG tool is installed
gpg_detect() {
  if command -v "gpg" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Function to install the GPG tool
install_gpg_tool() {
  pm=$1 # Get the package manager from the first argument
  case "$pm" in
  "pacman") sudo pacman -Syu && sudo pacman -S gnupg ;;
  "dnf") sudo dnf update && sudo dnf install gnupg ;;
  "apt") sudo apt update && sudo apt upgrade && sudo apt install gnupg ;;
  "zypper") sudo zypper update && sudo zypper install gnupg ;;
  "yum") sudo yum update && sudo yum install gnupg ;;
  esac
}

# Function to create a GPG key
create_gpg_key() {
  clear

  # Read user input for key details
  read -p "Enter your name: " name
  read -p "Enter your email: " email
  read -p "Enter the expiration date (in days): " expire
  echo
  read -s -p "Enter a passphrase: " passphrase
  echo
  read -p "Choose the key difficulty: 1) Easy 2) Medium 3) Hard: " difficulty

  # Set key length based on difficulty
  case "$difficulty" in
  1) key_length=2048 ;;
  2) key_length=3072 ;;
  3) key_length=4096 ;;
  esac

  # Generate a Batch file for GPG
  cat >gpg_batch <<EOF
%echo Generating a standard key
Key-Type: RSA
Key-Length: $key_length
Subkey-Type: RSA
Subkey-Length: $key_length
Name-Real: $name
Name-Email: $email
Expire-Date: $expire
Passphrase: $passphrase
%commit
%echo done
EOF

  # Generate the GPG key
  gpg --batch --gen-key gpg_batch

  # Remove the batch file
  rm gpg_batch

  echo "The GPG key has been created"
  read -p "Press Enter to continue.."

  # Redirect to the main menu
  menu
}

# Function to delete a key (placeholder)
delete_key() {
  while (true); do
    clear
    list_gpg_keys "false"
    selected_key=$(select_gpg_key)

    if [ -z "$selected_key" ]; then
      echo "Invalid key selected"
    else
      echo "Selected key: $selected_key"
      read -r -p "Are you sure you want to delete the key? (y/n): " answer

      if [[ "${answer,,}" =~ ^(y|yes)$ ]]; then
        gpg --delete-secret-keys "$selected_key"
        gpg --delete-keys "$selected_key"
        echo "Key deleted successfully"
        read -p "Press Enter to continue.."
        menu
      else
        read -r -p "Do you want to delete another key? (y/n): " another_key

        if [[ "${another_key,,}" =~ ^(n|no)$ ]]; then
          menu
          return
        fi
      fi
    fi
  done
}

# Function to redirect to the main menu
redirect_menu() {
  echo "Redirecting to the main menu.."
  sleep 2
  menu
}

# Function to get the GPG keys
get_gpg_keys() {
  is_formated=$1

  gpg_keys=$(gpg --list-secret-keys --keyid-format LONG)

  if [ "$is_formated" = "true" ]; then
    gpg_keys_info=$(echo "$gpg_keys" | grep -A1 "sec" | grep -v "sec" | grep -v -- "^--" | awk '{print $1}')
    formatted_keys=()
    count=1

    while IFS= read -r key_id; do
      key_info=$(gpg --list-secret-keys --keyid-format LONG "$key_id")
      author_name=$(echo "$key_info" | grep uid | sed 's/uid\s*//;s/<.*>//')
      author_email=$(echo "$key_info" | grep uid | sed 's/.*<//;s/>.*//')
      expiration_date=$(echo "$key_info" | grep "expire" | awk '{print $NF}' | sed 's/\[//;s/\].*//' | grep -oP '\d{4}-\d{2}-\d{2}')
      formatted_keys+=("Key Number: $count\nKey ID: $key_id\nKey Content: $author_name <$author_email>\nExpired date: $expiration_date\n")
      count=$((count + 1))
    done <<<"$gpg_keys_info"

    echo "${formatted_keys[@]}"
  else
    echo "$gpg_keys"
  fi
}

# Function to get the length of GPG keys
get_gpg_keys_length() {
  gpg_keys=$(get_gpg_keys "false")
  gpg_keys_length=$(echo "$gpg_keys" | grep -A1 "sec" | grep -v "sec" | grep -v -- "^--" | grep -c .)
  echo "$gpg_keys_length"
}

# Function to check GPG keys
check_gpg_keys() {
  # Check if there are any GPG keys available
  keys_length=$(get_gpg_keys_length)

  # If there are no keys, ask the user to create a new key
  if [ "$keys_length" -eq 0 ]; then
    read -r -p "No GPG keys found, do you want to create a new key? (y/n): " answer

    if [[ "${answer,,}" =~ ^(y|yes)$ ]]; then
      create_gpg_key
    else
      echo "false"
    fi
  else
    gpg_keys_output=$(get_gpg_keys "true")
    echo "$gpg_keys_output"
  fi
}

# Function to list GPG keys
list_gpg_keys() {

  # If this argument is true, only list the keys and return to the main menu. Otherwise, continue with the function.
  only_list=$1
  has_keys=$(check_gpg_keys)
  formatted_keys=$(get_gpg_keys "true")

  if [ "$has_keys" = "false" ]; then
    redirect_menu
  else
    clear

    echo -e "Available GPG keys:\n"

    for key in "${formatted_keys[@]}"; do
      echo -e "$key"
    done

    if [ "$only_list" = "true" ]; then
      read -p "Press Enter to continue.."
      menu
    fi
  fi
}

# Function to select a GPG key or recipient
select_gpg_key() {
  gpg_keys=$(get_gpg_keys "false")
  gpg_keys_length=$(get_gpg_keys_length)

  if [ "$gpg_keys_length" -eq 0 ]; then
    redirect_menu
  else
    while true; do
      read -p "Enter the key number to select a recipient: " key_number

      if [ "$key_number" -gt 0 ] && [ "$key_number" -le "$gpg_keys_length" ]; then
        selected_key=$(echo "$gpg_keys" | grep -A1 "sec" | grep -v "sec" | grep -v -- "^--" | sed -n "${key_number}p" | awk '{print $1}')
        echo "$selected_key"
        break
      fi
    done
  fi
}

# Function to clear expired keys (placeholder)
clear_expired_keys() {
  echo "Clearing expired keys.."
  sleep 2
}

# Function to encrypt a file
#FIXME - We are getting a “File Not Found” error. Rewrite the controls.
encrypt_file() {
  clear
  list_gpg_keys "false"
  selected_recipient=$(select_gpg_key)

  if [ "$selected_recipient" = "false" ]; then
    menu
  fi

  while true; do
    read -r -p "Enter the file path to encrypt (e.g., /path/to/file.[extension]): " file_path
    read -r -p "Enter the output path (e.g., /path/to/output.[extension].gpg): " output_path

    #Expand tilde (~) in file paths
    file_path=$(eval echo "$file_path")
    output_path=$(eval echo "$output_path")

    hasfile=$(file "$file_path" 2>&1 | grep -c "No such file or directory")

    if [ "$hasfile" -eq 1 ]; then
      echo "File not found: $file_path"

      read -r -p "Do you want to try again? (y/n): " try_again
      if [[ "${try_again,,}" =~ ^(n|no)$ ]]; then
        menu
        return
      fi
    else
      # Check output file and directory exists
      check_output "encrypt" "$output_path"

      # Encrypt the file and capture any errors
      gpg_output=$(gpg --quiet --encrypt --recipient "$selected_recipient" --output "$output_path" "$file_path" 2>&1)
      gpg_exit_code=$?

      if [ $gpg_exit_code -ne 0 ]; then
        echo "Error encrypting file: $gpg_output"
        read -p "Press Enter to continue.."
        menu
        return
      fi

      echo "File encrypted successfully"
      echo "Saved as: $output_path"

      # Ask about deleting original file
      read -r -p "Do you want to delete the original file? (y/n): " delete_original
      if [[ "${delete_original,,}" =~ ^(y|yes)$ ]]; then
        rm "$file_path"
        echo "Original file has been deleted"
      fi

      read -p "Press Enter to continue.."
      menu
      return
    fi
  done
}

# Function to decrypt a file
decrypt_file() {
  clear
  while true; do
    read -r -p "Enter the file path to decrypt (e.g., /path/to/file.[extension].gpg): " file_path
    read -r -p "Enter the output path (e.g., /path/to/output.[extension]): " output_path

    #Expand tilde (~) in file paths
    file_path=$(eval echo "$file_path")
    output_path=$(eval echo "$output_path")

    hasfile=$(file "$file_path" 2>&1 | grep -c "No such file or directory")

    if [ "$hasfile" -eq 1 ]; then
      echo "File not found: $file_path"

      read -r -p "Do you want to try again? (y/n): " try_again
      if [[ "${try_again,,}" =~ ^(n|no)$ ]]; then
        menu
        return
      fi
    else
      # Check output file and directory exists  
      check_output "decrypt" "$output_path"

      # Decrypt the file and capture any errors
      gpg_output=$(gpg --quiet --decrypt --output "$output_path" "$file_path" 2>&1)
      gpg_exit_code=$?

      if [ $gpg_exit_code -ne 0 ]; then
        echo "Error decrypting file: $gpg_output"
        read -p "Press Enter to continue.."
        menu
        return
      fi

      echo "File decrypted successfully"
      echo "Saved as: $output_path"

      # Ask about deleting encrypted file
      read -r -p "Do you want to delete the encrypted file? (y/n): " delete_encrypted
      if [[ "${delete_encrypted,,}" =~ ^(y|yes)$ ]]; then
        rm "$file_path"
        echo "Encrypted file has been deleted"
      fi

      read -p "Press Enter to continue.."
      menu
      return
    fi
  done
}

# Encrypted and decrypted check output file exists and check if the output directory exists
check_output() {
  type=$1
  file_path=$2

  # Check if the output file exists
  if [ -f "$file_path" ]; then
    echo "The $type file already exists: $file_path"
    read -r -p "Do you want to overwrite it? (y/n): " overwrite_file
    if [[ "${overwrite_file,,}" =~ ^(n|no)$ ]]; then
      read -r -p "Enter the new output path: " new_output_path
      echo "$new_output_path"
      return
    fi
  fi

  # Check if the output directory exists
  output_dir=$(dirname "$file_path")
  if [ ! -d "$output_dir" ]; then
    echo "The output directory does not exist: $output_dir"
    read -r -p "Do you want to create it? (y/n): " create_dir
    if [[ "${create_dir,,}" =~ ^(y|yes)$ ]]; then
      mkdir -p "$output_dir"
      echo "Directory created: $output_dir"
    else
    #REVIEW - Maybe we should ask the user to enter a new output path
      echo "Exiting.."
      exit 1
    fi
  fi
  
}

# Function to display the main menu
menu() {
  clear
  while true; do
    echo """
    -------------------------------------------------------
      ___  ____  _  _  ____  ____  ____    __    ___  _   _ 
     / __)(  _ \( \/ )(  _ \(_  _)(  _ \  /__\  / __)( )_( )
    ( (__  )   / \  /  )___/  )(   ) _ < /(__)\ \__ \ ) _ ( 
     \___)(_)\_) (__) (__)   (__) (____/(__)(__)(___/(_) (_)
    -------------------------------------------------------
                                              - by @Aethrox

    1) Create a GPG key
    2) List GPG keys
    3) Encrypt a file
    4) Decrypt a file
    5) Delete expired keys
    6) Delete key
    7) Exit
    """

    read -p "Choose an option: " option

    case "$option" in
    1) create_gpg_key ;;
    2) list_gpg_keys "true" ;;
    3) encrypt_file ;;
    4) decrypt_file ;;
    5) clear_expired_keys ;;
    6) delete_key ;;
    7) exit ;;
    *) echo "Invalid option" ;;
    esac
  done
}

# Main function
main() {
  clear
  pm=$(pm_detect)
  if [ -z "$pm" ]; then
    echo "No package manager found"
    exit 1
  fi

  # Check if GPG tool is installed
  if ! gpg_detect; then
    echo "gnupg tool not found"
    echo "Do you want to install the GPG tool?"
    read -r answer
    if [ "$answer" = "y" ]; then
      install_gpg_tool "$pm"
    else
      echo "Exiting the GPG tool"
      exit 1
    fi
  fi

  # Display the main menu
  menu
}

# Execute the main function
main
