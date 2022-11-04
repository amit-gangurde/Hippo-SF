public class CustomIterable implements Iterable<sObject>{ 
    List<sObject> wrapList;
    public CustomIterable(List<sObject> wrapList){
        this.wrapList = wrapList;
    }
    public Iterator<sObject> Iterator(){        
        return new CustomIterator(wrapList); 
    } 
}