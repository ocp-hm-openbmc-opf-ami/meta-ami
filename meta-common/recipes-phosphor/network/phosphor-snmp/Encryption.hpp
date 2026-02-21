#include <string>
extern const char* aesKeyFile;
extern const char* aesIVFile;

#define AES_MAX_KEY_LENGTH 32  // 256 bits
#define AES_MAX_IV_LENGTH 16   // 128 bits

char* base64_encode(const unsigned char* input, int length);
unsigned char* base64_decode(const char* input, int* out_length);
bool AES_GenerateAndSaveKeys(const char* keyFile, const char* ivFile);
int AES_GetKeyFromFile(const char* filename, unsigned char* buffer, int buffer_size);
std::string encryptString(const std::string& plaintext);
std::string decryptString(const std::string& b64Ciphertext,int* out_plaintext_len);
