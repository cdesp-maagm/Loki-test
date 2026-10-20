
%nodefaultctor LokiSocketServer;
%nodefaultdtor LokiSocketServer;

struct LokiSocketServer {};

%extend LokiSocketServer {
    LokiSocketServer(const char *filename) {
        return LokiSocketServer_new(filename);
    }

    ~LokiSocketServer() {
        LokiSocketServer_del($self);
    }

    int start(LokiFIFO *in, size_t cid=0);
    bool is_streaming();
    void stop();
}
