public enum FramesErrors: Error {
	case FATAL_ERROR(message: String)
	case NETWORK_ERROR(message: String)
	case TIMEOUT_ERROR(message: String = "The request timed out")
	case FORM_ERROR(message: String)
	case EVAL_ERROR(message: String)
}
