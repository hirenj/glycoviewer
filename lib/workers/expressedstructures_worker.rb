require 'open3'
class ExpressedstructuresWorker < BackgrounDRb::MetaWorker
  set_worker_name :expressedstructures_worker
  def create(args = nil)
    # this method is called, when worker is loaded for the first time
  end
  
  def o_linked_expression(bitfields)
    return expression('o-linked-geneassoc',bitfields)
  end
  
  def n_linked_expression(bitfields)
    return expression('n-linked-geneassoc',bitfields)
  end
  
  def expression(type,bitfields)
    logger.info(job_key,"Dispatching job key #{job_key}")
    
    if cache[job_key]
      logger.info(job_key,"Going to the cache for #{job_key}, returning")
      return nil
    end
    
    cache[job_key] = true
    
    f = IO.popen("./a.out #{type} #{bitfields[0]} #{bitfields[1]} #{bitfields[2]} 2> /Users/hirenj/dev/SugarImport/GlycoEnzyme/log/expression.log")
    result_text = f.readlines || " "      
    f.close
    
    logger.info(job_key,"Complete job key #{job_key}")
    if result_text.size > 256
      cache[job_key] = ["#{result_text.size} results"]
    else
      cache[job_key] = result_text
    end
    logger.info(job_key,"Total results are #{cache[job_key]}")
    return nil
  end
end

