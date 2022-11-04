public class CustomIterator implements Iterator<sObject>{ 
 
   private List<sObject> obj;
   private Integer currentIndex;
   private Integer temp;
   public CustomIterator(List<sObject> obj){
       this.obj = obj;
       this.currentIndex = 0;
   }
 
   public boolean hasNext(){ 
       if( obj!=null &&  obj.size()>0){
       return currentIndex < obj.size();
       }else{
         return false;  
       }
   }    
 
   public sObject next(){
       if(hasNext()) {
           temp = currentIndex;
           currentIndex++;
           return obj[temp];
       } else {
           throw new NoSuchElementException();
       }
   } 
}