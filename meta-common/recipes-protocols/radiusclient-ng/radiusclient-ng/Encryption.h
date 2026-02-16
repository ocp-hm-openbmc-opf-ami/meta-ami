// Encryption.h
#ifndef ENCRYPTION_H
#define ENCRYPTION_H

#include <openssl/evp.h>
#include <openssl/rand.h>
#include <openssl/conf.h>
#include <openssl/bio.h>
#include <openssl/buffer.h>

static const char* aesKeyFile = "/etc/radiusclient-ng/AESKey";
static const char* aesIVFile = "/etc/radiusclient-ng/AESIV";

#define AES_MAX_KEY_LENGTH 32
#define AES_MAX_IV_LENGTH 16

static inline unsigned char* base64_decode(const char* input, int* out_length) {
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

static inline int AES_GetKeyFromFile(const char* filename, unsigned char* buffer, int buffer_size) {
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

static inline char* decryptString(const unsigned char* ciphertext, int ciphertext_len) {
    // Check if key files exist
    FILE* keyFile = fopen(aesKeyFile, "rb");
    FILE* ivFile = fopen(aesIVFile, "rb");
    if (!keyFile || !ivFile) {
        if (keyFile) fclose(keyFile);
        if (ivFile) fclose(ivFile);
        fprintf(stderr, "AES key/IV files not found\n");
        return "";
    }
    fclose(keyFile);
    fclose(ivFile);

    unsigned char key[AES_MAX_KEY_LENGTH] = {0};
    unsigned char iv[AES_MAX_IV_LENGTH] = {0};

    if (AES_GetKeyFromFile(aesKeyFile, key, AES_MAX_KEY_LENGTH) < 0) {
        fprintf(stderr, "Failed to read AES key\n");
        return "";
    }

    if (AES_GetKeyFromFile(aesIVFile, iv, AES_MAX_IV_LENGTH) < 0) {
        fprintf(stderr, "Failed to read AES IV\n");
        return "";
    }

    EVP_CIPHER_CTX *ctx;
    int len;
    int plaintext_len;

    // Allocate buffer for plaintext
    unsigned char *plaintext = (unsigned char *)malloc(ciphertext_len + EVP_MAX_BLOCK_LENGTH);
    if (!plaintext) {
        fprintf(stderr, "Memory allocation failed\n");
        return NULL;
    }

    if(!(ctx = EVP_CIPHER_CTX_new())) {
        free(plaintext);
        fprintf(stderr, "Failed to create EVP context\n");
        return NULL;
    }

    if(1 != EVP_DecryptInit_ex(ctx, EVP_aes_256_cbc(), NULL, key, iv)) {
        EVP_CIPHER_CTX_free(ctx);
        free(plaintext);
        fprintf(stderr, "Failed to initialize decryption\n");
        return NULL;
    }

    if(1 != EVP_DecryptUpdate(ctx, plaintext, &len, ciphertext, ciphertext_len)) {
        EVP_CIPHER_CTX_free(ctx);
        free(plaintext);
        fprintf(stderr, "Decryption update failed\n");
        return NULL;
    }
    plaintext_len = len;

    if(1 != EVP_DecryptFinal_ex(ctx, plaintext + len, &len)) {
        EVP_CIPHER_CTX_free(ctx);
        free(plaintext);
        fprintf(stderr, "Decryption finalization failed\n");
        return NULL;
    }
    plaintext_len += len;

    EVP_CIPHER_CTX_free(ctx);

    // Add null terminator
    plaintext[plaintext_len] = '\0';

    return (char*)plaintext;
}
#endif /* ENCRYPTION_H */
