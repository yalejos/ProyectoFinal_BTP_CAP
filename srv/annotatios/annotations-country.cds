using {SalesOrder as service} from '../service';

annotate service.Countries with {
     @title: 'Countries'
     code @Common: {
         Text : name,
         TextArrangement: #TextOnly
     }
} ;