
%nodefaultctor LokiFIFO;
%nodefaultdtor LokiFIFO;

struct LokiFIFO {};

%extend LokiFIFO {
    LokiFIFO(size_t item_size, size_t length, size_t consumers=1) {
        return LokiFIFO_new(item_size, length, consumers);
    }

    ~LokiFIFO() {
        LokiFIFO_del($self);
    }
}
