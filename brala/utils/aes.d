module brala.utils.aes;

private {
    import std.conv : to;
    
    import deimos.openssl.evp;
    import deimos.openssl.err;
}


string get_openssl_error() {
    uint e = ERR_get_error();
    char[] buf = new char[512];
    ERR_error_string(e, buf.ptr);
    return to!string(buf.ptr); // to!string stops at \0
}


class AESError : Exception {
    this(string msg) {
        super(msg);
    }
}

class AES(alias gen) {
    const(ubyte)[] key;
    const(ubyte)[] iv;

    ENGINE* engine = null;
    EVP_CIPHER_CTX ctx_encrypt;
    EVP_CIPHER_CTX ctx_decrypt;

    protected bool _encrypt_finalized = false;
    protected bool _decrypt_finalized = false;

    @property bool enctypt_finalized() { return _encrypt_finalized; }
    @property bool decrypt_finalized() { return _decrypt_finalized; }

    protected uint _block_size;
    
    this(const(ubyte)[] key, const(ubyte)[] iv) {
        this.key = key;
        this.iv = iv;

        EVP_CIPHER_CTX_init(&ctx_encrypt);
        EVP_EncryptInit_ex(&ctx_encrypt, gen(), engine, key.ptr, iv.ptr);
        
        EVP_CIPHER_CTX_init(&ctx_decrypt);
        EVP_DecryptInit_ex(&ctx_decrypt, gen(), engine, key.ptr, iv.ptr);

        _block_size = EVP_CIPHER_block_size(gen());
    }

    ~this() {
        EVP_CIPHER_CTX_cleanup(&ctx_encrypt);
        EVP_CIPHER_CTX_cleanup(&ctx_decrypt);
    }

    ubyte[] encrypt(const(void)* data, size_t size)
        in { assert(!_encrypt_finalized); }
        body {
            ubyte[] out_ = new ubyte[size + _block_size-1];
            int outlen;
            if(!EVP_EncryptUpdate(&ctx_encrypt, out_.ptr, &outlen, cast(const(ubyte)*)data, cast(int)size)) {
                throw new AESError(get_openssl_error());
            }
            out_.length = outlen;

            return out_;
        }

    ubyte[] decrypt(const(void)* data, size_t size)
        in { assert(!_decrypt_finalized); }
        body {
            ubyte[] out_ = new ubyte[size + _block_size];
            int outlen;
            if(!EVP_DecryptUpdate(&ctx_decrypt, out_.ptr, &outlen, cast(const(ubyte)*)data, cast(int)size)) {
                throw new AESError(get_openssl_error());
            }
            out_.length = outlen;

            return out_;
        }

    ubyte[] encrypt_finalize()
        in { assert(!_encrypt_finalized); }
        body {
            ubyte[] out_ = new ubyte[_block_size];
            int outlen;

            if(!EVP_EncryptFinal_ex(&ctx_encrypt, out_.ptr, &outlen)) {
                throw new AESError(get_openssl_error());
            }
            out_.length = outlen;

            _encrypt_finalized = true;

            return out_;
        }

    ubyte[] decrypt_finalize()
        in { assert(!_decrypt_finalized); }
        body {
            ubyte[] out_ = new ubyte[_block_size];
            int outlen;

            if(!EVP_DecryptFinal_ex(&ctx_decrypt, out_.ptr, &outlen)) {
                throw new AESError(get_openssl_error());
            }
            out_.length = outlen;

            _decrypt_finalized = true;

            return out_;
        }
}

alias AES!(EVP_aes_128_cfb8) AES128CFB8;