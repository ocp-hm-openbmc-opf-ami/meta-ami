#include <openssl/evp.h>
#include <openssl/rand.h>
#include <openssl/conf.h>
#include <openssl/err.h>
#include <openssl/bio.h>
#include <openssl/buffer.h>

const char* aesKeyFile = "/etc/radiusclient-ng/AESKey";
const char* aesIVFile = "/etc/radiusclient-ng/AESIV";

#define AES_MAX_KEY_LENGTH 32  // 256 bits
#define AES_MAX_IV_LENGTH 16   // 128 bits

char* base64_encode(const unsigned char* input, int length) {
    BIO *bio, *b64;
    BUF_MEM *bufferPtr;

    b64 = BIO_new(BIO_f_base64());
    bio = BIO_new(BIO_s_mem());
    bio = BIO_push(b64, bio);

    BIO_set_flags(bio, BIO_FLAGS_BASE64_NO_NL);
    BIO_write(bio, input, length);
    BIO_flush(bio);
    BIO_get_mem_ptr(bio, &bufferPtr);
    
    char* output = (char*)malloc(bufferPtr->length + 1);
    memcpy(output, bufferPtr->data, bufferPtr->length);
    output[bufferPtr->length] = '\0';

    BIO_free_all(bio);
    return output;
}

unsigned char* base64_decode(const char* input, int* out_length) {
    BIO *bio, *b64;
    int decodeLen = strlen(input);
    if (decodeLen <= 0) {
        *out_length = 0;
        return NULL;
    }
    unsigned char* buffer = (unsigned char*)malloc(decodeLen + 1);
    if (!buffer) {
        *out_length = 0;
        return NULL;
    }

    bio = BIO_new_mem_buf(input, -1);
    b64 = BIO_new(BIO_f_base64());
    bio = BIO_push(b64, bio);
    BIO_set_flags(bio, BIO_FLAGS_BASE64_NO_NL);
    
    *out_length = BIO_read(bio, buffer, decodeLen);
    if (*out_length < 0 || *out_length > decodeLen) {
        free(buffer);
        BIO_free_all(bio);
        *out_length = 0;
        return NULL;
    }
    BIO_free_all(bio);
    
    return buffer;
}

bool AES_GenerateAndSaveKeys(const char* keyFile, const char* ivFile) {
    unsigned char key[AES_MAX_KEY_LENGTH];
    unsigned char iv[AES_MAX_IV_LENGTH];
    
    // Generate random key and IV
    if (RAND_bytes(key, AES_MAX_KEY_LENGTH) != 1 ||
        RAND_bytes(iv, AES_MAX_IV_LENGTH) != 1) {
        return false;
    }
    
    // Encode key and IV in base64 for storage
    char* encodedKey = base64_encode(key, AES_MAX_KEY_LENGTH);
    char* encodedIV = base64_encode(iv, AES_MAX_IV_LENGTH);
    
    // Save to files
    FILE* fkey = fopen(keyFile, "wb");
    FILE* fiv = fopen(ivFile, "wb");
    if (!fkey || !fiv) {
        free(encodedKey);
        free(encodedIV);
        if (fkey) fclose(fkey);
        if (fiv) fclose(fiv);
        return false;
    }
    
    fwrite(encodedKey, 1, strlen(encodedKey), fkey);
    fwrite(encodedIV, 1, strlen(encodedIV), fiv);
    
    fclose(fkey);
    fclose(fiv);
    free(encodedKey);
    free(encodedIV);
    
    return true;
}

int AES_GetKeyFromFile(const char* filename, unsigned char* buffer, int buffer_size) {
    FILE* file = fopen(filename, "rb");
    if (!file) {
        return -1;
    }
    
    fseek(file, 0, SEEK_END);
    long file_size = ftell(file);
    fseek(file, 0, SEEK_SET);
    
    char* encoded = (char*)malloc(file_size + 1);
    if (!encoded) {
        fclose(file);
        return -1;
    }
    
    fread(encoded, 1, file_size, file);
    encoded[file_size] = '\0';
    fclose(file);
    
    int out_len;
    unsigned char* decoded = base64_decode(encoded, &out_len);
    free(encoded);
    
    if (out_len != buffer_size) {
        free(decoded);
        return -1;
    }
    
    memcpy(buffer, decoded, buffer_size);
    free(decoded);
    
    return 0;
}

std::string encryptString(const std::string& plaintext) {


    FILE* keyFile = fopen(aesKeyFile, "rb");
    FILE* ivFile = fopen(aesIVFile, "rb");
    if (!keyFile || !ivFile) {
        if (keyFile) fclose(keyFile);
        if (ivFile) fclose(ivFile);
        if (!AES_GenerateAndSaveKeys(aesKeyFile, aesIVFile)) {
            std::cerr << "Failed to generate AES key/IV files" << std::endl;
            return "";
        }
    } else {
        fclose(keyFile);
        fclose(ivFile);
    }

    unsigned char key[AES_MAX_KEY_LENGTH];
    unsigned char iv[AES_MAX_IV_LENGTH];

    if (AES_GetKeyFromFile(aesKeyFile, key, AES_MAX_KEY_LENGTH) < 0) {
        std::cerr << "Failed to read AES key" << std::endl;
        return "";
    }

    if (AES_GetKeyFromFile(aesIVFile, iv, AES_MAX_IV_LENGTH) < 0) {
        std::cerr << "Failed to read AES IV" << std::endl;
        return "";
    }

    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    if (!ctx) {
        std::cerr << "Failed to create EVP context" << std::endl;
        return "";
    }

    if (1 != EVP_EncryptInit_ex(ctx, EVP_aes_256_cbc(), NULL, key, iv)) {
        std::cerr << "Failed to initialize encryption" << std::endl;
        EVP_CIPHER_CTX_free(ctx);
        return "";
    }

    int len;
    int ciphertext_len;
    std::vector<unsigned char> ciphertext(plaintext.size() + EVP_MAX_BLOCK_LENGTH);

    if (1 != EVP_EncryptUpdate(ctx, ciphertext.data(), &len,
                            reinterpret_cast<const unsigned char*>(plaintext.c_str()),
                            plaintext.length())) {
        std::cerr << "Encryption update failed" << std::endl;
        EVP_CIPHER_CTX_free(ctx);
        return "";
    }
    ciphertext_len = len;

    if (1 != EVP_EncryptFinal_ex(ctx, ciphertext.data() + len, &len)) {
        std::cerr << "Encryption finalization failed" << std::endl;
        EVP_CIPHER_CTX_free(ctx);
        return "";
    }
    ciphertext_len += len;

    EVP_CIPHER_CTX_free(ctx);
    char* b64 = base64_encode(ciphertext.data(), ciphertext_len);
    if (!b64)
    {
	    std::cerr << "Base64 encoding failed" << std::endl;
	    return "";
    }
    std::string encoded(b64);
    free(b64);
    
    return encoded;
}
