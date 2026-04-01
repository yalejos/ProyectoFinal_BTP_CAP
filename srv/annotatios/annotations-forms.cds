using {SalesOrder as service} from '../service';

annotate service.formDelivery with {
    fdeliverydate @title: 'Delivery Date'; 
};

annotate service.formRelease with {
    freleasedate @title: 'Release Date'; 
};