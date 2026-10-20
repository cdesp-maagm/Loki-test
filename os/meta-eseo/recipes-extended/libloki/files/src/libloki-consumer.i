
%nodefaultctor LokiConsumer;
%nodefaultdtor LokiConsumer;

struct LokiConsumer {};

%extend LokiConsumer {
    LokiConsumer() {
        return LokiConsumer_new();
    }

    ~LokiConsumer() {
        LokiConsumer_del($self);
    }

    int start(LokiFIFO *in, size_t cid=0);
    void stop();
}
