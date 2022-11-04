public class CustomIterableString implements Iterable<String>{
    List<String> wrapList;
    public CustomIterableString(List<String> wrapList){
        this.wrapList = wrapList;
    }
    public Iterator<String> Iterator(){        
        return new CustomIteratorString(wrapList); 
    } 
}